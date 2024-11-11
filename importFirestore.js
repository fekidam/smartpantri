const admin = require("firebase-admin");
const fs = require("fs");

// Initialize Firebase Admin SDK
const serviceAccount = require("./serviceAccountKey.json");
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const db = admin.firestore();

// Load data from JSON file
const data = JSON.parse(fs.readFileSync("products.json", "utf8"));

async function importData() {
  const productsCollection = db.collection("products");

  // Iterate over each product in the data object
  for (const [id, product] of Object.entries(data.products)) {
    await productsCollection.doc(id).set(product);
    console.log(`Added product: ${product.name}`);
  }

  console.log("All products have been added to Firestore.");
}

importData().catch(console.error);
