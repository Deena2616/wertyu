
const express = require('express');
const admin = require('firebase-admin');
const cors = require('cors');
const dotenv = require('dotenv');
const path = require('path');

// Load environment variables
dotenv.config();
const app = express();
const port = process.env.PORT || 3000;

// Enable CORS for all routes
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));

app.use(express.json({ limit: '10mb' }));

// Initialize Firebase
let db;
let firebaseInitialized = false;

async function initializeFirebase() {
  if (firebaseInitialized) return true;

  try {
    let serviceAccount;

    // Check if using a service account file
    if (process.env.FIREBASE_SERVICE_ACCOUNT_FILE) {
      const serviceAccountPath = path.join(__dirname, process.env.FIREBASE_SERVICE_ACCOUNT_FILE);
      console.log('Loading service account from:', serviceAccountPath);

      // Check if file exists
      if (!require('fs').existsSync(serviceAccountPath)) {
        throw new Error(`Service account file not found at: ${serviceAccountPath}`);
      }

      serviceAccount = require(serviceAccountPath);
    }
    // Otherwise check if the service account is provided as a JSON string
    else if (process.env.FIREBASE_SERVICE_ACCOUNT) {
      console.log('Loading service account from environment variable');
      try {
        serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT);
      } catch (parseError) {
        throw new Error(`Failed to parse FIREBASE_SERVICE_ACCOUNT JSON: ${parseError.message}`);
      }
    } else {
      throw new Error('Firebase service account not provided. Set FIREBASE_SERVICE_ACCOUNT_FILE or FIREBASE_SERVICE_ACCOUNT');
    }

    // Validate required service account fields
    const requiredFields = ['type', 'project_id', 'private_key_id', 'private_key', 'client_email', 'client_id'];
    for (const field of requiredFields) {
      if (!serviceAccount[field]) {
        throw new Error(`Service account missing required field: ${field}`);
      }
    }

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });

    db = admin.firestore();
    firebaseInitialized = true;
    console.log('Firebase initialized successfully');
    return true;
  } catch (error) {
    console.error('Failed to initialize Firebase:', error.message);
    firebaseInitialized = false;
    return false;
  }
}

// Form submission endpoint
app.post('/submit-form', async (req, res) => {
  if (!firebaseInitialized) {
    const initialized = await initializeFirebase();
    if (!initialized) {
      return res.status(500).json({
        success: false,
        error: 'Firebase not initialized'
      });
    }
  }

  try {
    console.log('Received form data:', req.body);

    // Validate required fields
    const { username, email, password } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields: username, email, password'
      });
    }

    // Basic email validation
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid email format'
      });
    }

    // Prepare form data with additional metadata
    const formData = {
      ...req.body,
      submittedAt: admin.firestore.FieldValue.serverTimestamp(),
      ipAddress: req.ip,
      userAgent: req.get('User-Agent')
    };

    // Save to Firestore
    const docRef = await db.collection('form_submissions').add(formData);
    console.log('Form submitted with ID:', docRef.id);

    res.status(200).json({
      success: true,
      id: docRef.id,
      message: 'Form submitted successfully'
    });
  } catch (error) {
    console.error('Error submitting form:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Get all form submissions with pagination
app.get('/form-submissions', async (req, res) => {
  if (!firebaseInitialized) {
    const initialized = await initializeFirebase();
    if (!initialized) {
      return res.status(500).json({
        success: false,
        error: 'Firebase not initialized'
      });
    }
  }

  try {
    // Parse pagination parameters
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 10;
    const offset = (page - 1) * limit;

    // Get total count for pagination metadata
    const snapshotCount = await db.collection('form_submissions').count().get();
    const totalCount = snapshotCount.data().count;

    // Get paginated submissions
    const snapshot = await db.collection('form_submissions')
      .orderBy('submittedAt', 'desc')
      .offset(offset)
      .limit(limit)
      .get();

    const submissions = [];
    snapshot.forEach(doc => {
      submissions.push({
        id: doc.id,
        ...doc.data()
      });
    });

    res.status(200).json({
      success: true,
      submissions: submissions,
      pagination: {
        totalCount,
        currentPage: page,
        totalPages: Math.ceil(totalCount / limit),
        limit
      }
    });
  } catch (error) {
    console.error('Error fetching form submissions:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'OK',
    firebase: firebaseInitialized ? 'Initialized' : 'Not initialized'
  });
});

// Start server
initializeFirebase().then(() => {
  app.listen(port, () => {
    console.log(`Server running at http://localhost:${port}`);
  });
}).catch((error) => {
  console.error('Failed to start server:', error.message);
  process.exit(1);
});
