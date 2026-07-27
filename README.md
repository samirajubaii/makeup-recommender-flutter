Blush & Buy — Makeup Recommendation App (Flutter Frontend)

A mobile e-commerce app that recommends makeup products to users based on facial landmark detection. Built as part of an internship project, this repo contains the Flutter frontend; the companion Node.js/Express backend lives at makeup-recommender-backend.

Overview

Blush & Buy lets users scan their face to get personalized product recommendations, then browse, shop, and check out within the app — combining computer vision with a full e-commerce flow.

Features


Face scan & recommendations — facial landmark detection drives personalized makeup suggestions
Product catalog — browse by brand, category, and shade
Cart & checkout — full shopping cart and order flow
User accounts — registration, login, and order history
Admin panel — manage products, brands, categories, and orders


Tech Stack


Framework: Flutter / Dart
State management: Provider
Backend: Node.js, Express (see backend repo)
Computer vision: Facial landmark detection for recommendation input


Project Structure

lib/
├── core/api/        # API client and constants
├── models/          # Data models (product, brand, order, user, etc.)
├── providers/        # State management (auth, cart, catalog, recommendations)
├── screens/
│   ├── admin/        # Admin dashboard and management screens
│   ├── ai/            # Face scan screen
│   ├── auth/          # Login and registration
│   ├── cart/           # Cart and checkout
│   ├── home/            # Home and shop tabs
│   ├── orders/            # Order history
│   └── product/            # Product details
└── widgets/                  # Reusable UI components

Getting Started


Install Flutter
Clone this repo and install dependencies:


   git clone https://github.com/samirajubaii/makeup-recommender-flutter.git
   cd makeup-recommender-flutter
   flutter pub get


Update the backend URL in lib/api.dart and lib/core/api/constants.dart to point to your own backend instance
Run the app:


   flutter run

Backend

This app is designed to work with a companion Express backend. See makeup-recommender-backend for setup instructions.

Author

Samira Jubaii
GitHub
