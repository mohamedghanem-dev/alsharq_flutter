class Category {
  final String id, name;
  final String? image;
  Category({required this.id, required this.name, this.image});
}

// Keep alias for backward compat
typedef MenuCategory = Category;

class MenuItem {
  final String id, name, categoryId;
  final double price;
  final double? salePrice;
  final String? image, description;
  final bool available;
  MenuItem({required this.id, required this.name, required this.categoryId,
    required this.price, this.salePrice, this.image, this.description, this.available = true});
}

class Offer {
  final String id, title;
  final String? description, image, expiresAt;
  final int discount;
  Offer({required this.id, required this.title, this.description,
    this.image, this.expiresAt, this.discount = 0});
}

class Review {
  final String id, name;
  final int stars;
  final String? comment;
  Review({required this.id, required this.name, required this.stars, this.comment});
}

class RestaurantOrder {
  final String id, status;
  final double total;
  final dynamic items;
  final String? customerName, address, phone, paymentMethod;
  final DateTime? createdAt;
  Order({required this.id, required this.status, required this.total,
    required this.items, this.customerName, this.address, this.phone,
    this.paymentMethod, this.createdAt});
}
