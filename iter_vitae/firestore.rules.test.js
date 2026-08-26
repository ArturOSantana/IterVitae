/**
 * Testes de segurança das regras do Firestore — Iter Vitae
 *
 * Executa com:
 *   npm install -D @firebase/rules-unit-testing
 *   node --experimental-vm-modules node_modules/.bin/jest firestore.rules.test.js
 *
 * Ou diretamente via Firebase Emulator Suite:
 *   firebase emulators:exec "node firestore.rules.test.js"
 */

const {
  initializeTestEnvironment,
  assertFails,
  assertSucceeds,
} = require('@firebase/rules-unit-testing');
const fs = require('fs');

const PROJECT_ID = 'iter-vitae-test';

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: fs.readFileSync('firestore.rules', 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv.cleanup();
});

afterEach(async () => {
  await testEnv.clearFirestore();
});

// ── Helpers ──────────────────────────────────────────────────────────────────

function asUser(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function asDirector(uid) {
  return testEnv.authenticatedContext(uid).firestore();
}

function unauth() {
  return testEnv.unauthenticatedContext().firestore();
}

// ── Checklist de segurança ────────────────────────────────────────────────────

describe('Checklist 1 — diretor NÃO lê dados pessoais do dirigido', () => {
  const directorUid = 'director-001';
  const directeeUid = 'user-001';

  const personalCollections = [
    'practices',
    'reflections',
    'directions',
    'struggles',
    'books',
    'diary',
    'exame_diario',
    'exame_confissao',
    'virtues',
    'reading_sessions',
  ];

  personalCollections.forEach((col) => {
    test(`diretor não pode ler /users/${directeeUid}/${col}`, async () => {
      await assertFails(
        asDirector(directorUid)
          .collection(`users/${directeeUid}/${col}`)
          .get()
      );
    });

    test(`diretor não pode ler documento em /users/${directeeUid}/${col}/doc`, async () => {
      await assertFails(
        asDirector(directorUid)
          .doc(`users/${directeeUid}/${col}/doc-001`)
          .get()
      );
    });
  });

  test('diretor não pode ler o perfil /users/{directeeUid}', async () => {
    await assertFails(
      asDirector(directorUid).doc(`users/${directeeUid}`).get()
    );
  });
});

describe('Checklist 2 — diretor não lê dados de OUTRO diretor', () => {
  const directorA = 'director-A';
  const directorB = 'director-B';
  const directeeUid = 'user-002';

  test('diretor A não pode ler /directors/{directorB}/...', async () => {
    await assertFails(
      asDirector(directorA)
        .collection(`directors/${directorB}/directees`)
        .get()
    );
  });

  test('diretor A não pode ler vínculo em directors/directorB/directees', async () => {
    await assertFails(
      asDirector(directorA)
        .doc(`directors/${directorB}/directees/${directeeUid}`)
        .get()
    );
  });

  test('diretor A não pode ler relatórios de outro diretor', async () => {
    await assertFails(
      asDirector(directorA)
        .collection(`directors/${directorB}/directees/${directeeUid}/reports`)
        .get()
    );
  });
});

describe('Checklist 3 — diretor NÃO escreve em directees (apenas lê)', () => {
  const directorUid = 'director-C';
  const directeeUid = 'user-003';

  test('diretor não pode criar documento de vínculo de dirigido', async () => {
    await assertFails(
      asDirector(directorUid)
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .set({ apelido: 'hackeado', vinculadoEm: new Date() })
    );
  });

  test('diretor não pode atualizar apelido ou data do dirigido', async () => {
    // Primeiro o dirigido cria o vínculo
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .set({ apelido: 'Zé', vinculadoEm: new Date() });
    });

    await assertFails(
      asDirector(directorUid)
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .update({ apelido: 'alterado pelo diretor' })
    );
  });

  test('dirigido pode criar seu próprio vínculo', async () => {
    await assertSucceeds(
      asUser(directeeUid)
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .set({ apelido: 'Filipe', vinculadoEm: new Date() })
    );
  });

  test('dirigido pode atualizar seu próprio apelido/data', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx
        .firestore()
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .set({ apelido: 'Filipe', vinculadoEm: new Date() });
    });

    await assertSucceeds(
      asUser(directeeUid)
        .doc(`directors/${directorUid}/directees/${directeeUid}`)
        .update({ proximaDirecaoData: new Date() })
    );
  });
});

describe('Checklist 4 — código de convite expira e não pode ser reutilizado', () => {
  const directeeUid = 'user-004';
  const directorUid = 'director-D';
  const codigo = 'ABC123';

  test('dirigido pode criar código com usado=false', async () => {
    await assertSucceeds(
      asUser(directeeUid).doc(`invite_codes/${codigo}`).set({
        directeeUid,
        criadoEm: new Date(),
        expiraEm: new Date(Date.now() + 24 * 60 * 60 * 1000),
        usado: false,
      })
    );
  });

  test('código já marcado como usado=true não pode ser marcado novamente', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().doc(`invite_codes/${codigo}`).set({
        directeeUid,
        usado: true,
      });
    });

    await assertFails(
      asDirector(directorUid)
        .doc(`invite_codes/${codigo}`)
        .update({ usado: true })
    );
  });

  test('diretor não pode criar código', async () => {
    await assertFails(
      asDirector(directorUid).doc(`invite_codes/NOVO99`).set({
        directeeUid: 'outro',
        usado: false,
      })
    );
  });
});
