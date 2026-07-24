class ApiConstants {
  // your phone setup ✅
  static const String baseUrl = "https://makeup-recommender-backend-production.up.railway.app";

  // Catalog
  static const String products = "/api/products";
  static const String brands = "/api/brands";
  static const String categories = "/api/categories";

  // Auth
  static const String login = "/api/auth/login";
  static const String register = "/api/auth/signup";
  static const String me = "/api/auth/me"; // only if you made it

  // Cart (depends on your routes/cart.js paths)
  static const String cart = "/api/cart";
  static const String cartItems = "/api/cart/items";

  // Orders
  static const String orders = "/api/orders";

  // AI analyze (depends on routes/analyze.js paths)
  static const String analyze = "/api/analyze";
  static const String cartAdd = "/api/cart/items"; // maybe different in your backend
  static const String cartRemove = "/api/cart/items"; // used with /:id

  // ✅ Admin (protected)
  static const String adminBrands = "/api/admin/brands";
  static const String adminCategories = "/api/admin/categories";
  static const String adminProducts = "/api/admin/products";
  // Admin
  static const String adminUpload = "/api/admin/upload";
  static const String adminProductShades = "/api/admin/products"; // use /:id/shades
  static const String adminOrders = "/api/admin/orders";

}

