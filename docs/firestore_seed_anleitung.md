# Firestore Seed-Skript mit Node.js und Firebase Admin SDK

Anleitung zum automatisierten Hinzufügen von Testdaten in eine Firestore-Collection mithilfe von Node.js und dem Firebase Admin SDK.

---

## Voraussetzungen

- Node.js installiert
- Firebase-Projekt erstellt
- Firestore-Datenbank im Production Mode aktiviert
- Firebase Authentication aktiviert (E-Mail/Passwort)
- Testbenutzer in Firebase Authentication angelegt

---

## Schritt 1 – Service Account Schlüssel herunterladen

1. Firebase Console öffnen → Projekteinstellungen (Zahnrad oben links)
2. Reiter **„Service accounts"** auswählen
3. Auf **„Generate new private key"** klicken → **„Generate key"**
4. Die heruntergeladene JSON-Datei umbenennen: `serviceAccountKey.json`

---

## Schritt 2 – Projektordner erstellen und Abhängigkeiten installieren

```bash
mkdir expense_seeder
cd expense_seeder
npm init -y
npm install firebase-admin
```

Die Datei `serviceAccountKey.json` in den Ordner `expense_seeder` legen.

---

## Schritt 3 – User UID ermitteln

1. Firebase Console → **Authentication** → **Users**
2. Auf den Testbenutzer klicken
3. **User UID** kopieren

---

## Schritt 4 – Seed-Skript erstellen

Datei `seed.js` im Ordner `expense_seeder` erstellen:

```javascript
const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

// Firebase Admin SDK initialisieren
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// UID des Testbenutzers aus Firebase Authentication
const USER_ID = 'DEINE_UID_HIER';

// Testdaten für die Collection "expenses"
const expenses = [
  {
    amount: 47.50,
    category: 'food',
    date: new Date('2025-03-03'),
    note: 'Einkauf im Supermarkt',
    userId: USER_ID,
    createdAt: new Date('2025-03-03'),
  },
  {
    amount: 12.00,
    category: 'transport',
    date: new Date('2025-03-07'),
    note: 'U-Bahn Wochenkarte',
    userId: USER_ID,
    createdAt: new Date('2025-03-07'),
  },
  {
    amount: 89.90,
    category: 'health',
    date: new Date('2025-03-12'),
    note: 'Apotheke',
    userId: USER_ID,
    createdAt: new Date('2025-03-12'),
  },
  {
    amount: 35.00,
    category: 'entertainment',
    date: new Date('2025-03-15'),
    note: 'Kino',
    userId: USER_ID,
    createdAt: new Date('2025-03-15'),
  },
  {
    amount: 120.00,
    category: 'food',
    date: new Date('2025-03-20'),
    note: 'Restaurant mit Freunden',
    userId: USER_ID,
    createdAt: new Date('2025-03-20'),
  },
  {
    amount: 9.99,
    category: 'other',
    date: new Date('2025-03-25'),
    note: 'Spotify Abo',
    userId: USER_ID,
    createdAt: new Date('2025-03-25'),
  },
  {
    amount: 55.00,
    category: 'transport',
    date: new Date('2025-04-01'),
    note: 'Taxi',
    userId: USER_ID,
    createdAt: new Date('2025-04-01'),
  },
  {
    amount: 18.75,
    category: 'food',
    date: new Date('2025-04-03'),
    note: 'Kaffee und Frühstück',
    userId: USER_ID,
    createdAt: new Date('2025-04-03'),
  },
];

// Dokumente in Firestore speichern
async function seedExpenses() {
  const collectionRef = db.collection('expenses');

  for (const expense of expenses) {
    // collection.add() erstellt ein Dokument mit automatisch generierter ID
    await collectionRef.add(expense);
    console.log(`✓ Ausgabe hinzugefügt: ${expense.note}`);
  }

  console.log('\n✅ Alle Ausgaben erfolgreich gespeichert!');
  process.exit(0);
}

seedExpenses().catch((error) => {
  console.error('Fehler:', error);
  process.exit(1);
});
```

---

## Schritt 5 – Skript ausführen

```bash
node seed.js
```

Erwartete Ausgabe im Terminal:

```
✓ Ausgabe hinzugefügt: Einkauf im Supermarkt
✓ Ausgabe hinzugefügt: U-Bahn Wochenkarte
✓ Ausgabe hinzugefügt: Apotheke
✓ Ausgabe hinzugefügt: Kino
✓ Ausgabe hinzugefügt: Restaurant mit Freunden
✓ Ausgabe hinzugefügt: Spotify Abo
✓ Ausgabe hinzugefügt: Taxi
✓ Ausgabe hinzugefügt: Kaffee und Frühstück

✅ Alle Ausgaben erfolgreich gespeichert!
```

---

## Datenstruktur – Dokument in der Collection `expenses`

| Feld | Typ | Beschreibung |
|---|---|---|
| `amount` | number | Betrag der Ausgabe |
| `category` | string | Kategorie: `food`, `transport`, `health`, `entertainment`, `other` |
| `date` | Timestamp | Datum der Ausgabe |
| `note` | string | Kurze Beschreibung |
| `userId` | string | UID des Benutzers aus Firebase Authentication |
| `createdAt` | Timestamp | Erstellungszeitpunkt des Dokuments |

> Die Dokument-IDs werden automatisch von Firestore generiert (`collection.add()`). Das ist die Standardpraxis, da Firestore so eine gleichmäßige Verteilung der Daten garantiert.

---

## Hinweise

- `serviceAccountKey.json` **niemals** in ein öffentliches Repository (z. B. GitHub) hochladen
- Die Datei zu `.gitignore` hinzufügen:

```
serviceAccountKey.json
node_modules/
```

- Das Admin SDK umgeht die Security Rules — es ist nur für serverseitige Skripte gedacht, nicht für die Flutter-App selbst
