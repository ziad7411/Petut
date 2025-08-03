import 'package:flutter/material.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/Product.dart';
import 'package:petut/Data/fetchProducts.dart';
import 'package:petut/Data/card_data.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/cart_screen.dart';
import 'package:petut/screens/product_details_screen.dart';
import 'package:petut/screens/search_screen.dart';
import 'package:petut/screens/side_draw.dart';
import 'package:petut/screens/chats_list_screen.dart';
import 'package:petut/services/simple_chat_service.dart';
import '../models/Chat.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Product>> futureProducts;
  String selectedCategory = 'All';
  Set<String> favoriteIds = {};

final List<String> categories = ["All", "cat", "dog", "bird", "toys"];


  @override
  void initState() {
    super.initState();
    futureProducts = fetchProducts();
    loadFavorites();
  }

  Future<void> loadFavorites() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot =
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('favorites')
            .get();

    if (mounted) {
      setState(() {
        favoriteIds = snapshot.docs.map((doc) => doc.id).toSet();
      });
    }
  }

  List<Product> filterByCategory(List<Product> products, String category) {
    if (category == "All") return products;
    return products.where((p) => p.category == category).toList();
  }

  CardData convertProductToCard(Product product) {
    return CardData(
      id: product.id.toString(),
      title: product.name,
      description: product.details,
      image: product.image,
      price: product.price,
      rate: product.rate,
      weight: product.weight.replaceAll("g", ""),

      isFavorite: favoriteIds.contains(product.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const SideDraw(),
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Builder(
              builder:
                  (context) => IconButton(
                    icon: Icon(Icons.menu, color: theme.iconTheme.color),
                    onPressed: () {
                      Scaffold.of(context).openDrawer();
                    },
                  ),
            ),
            const SizedBox(width: 8),
            Text(
              'Home',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyMedium!.color,
              ),
            ),
          ],
        ),
        actions: [
          iconContainer(
            Icons.search,
            theme.iconTheme.color ?? Colors.grey,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SearchScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          FirebaseAuth.instance.currentUser != null
              ? StreamBuilder<List<Chat>>(
                  stream: SimpleChatService.getUserChats(),
                  builder: (context, snapshot) {
                    int unreadCount = 0;
                    if (snapshot.hasData) {
                      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId != null) {
                        unreadCount = snapshot.data!.fold(0, (sum, chat) => 
                          sum + (chat.unreadCount[currentUserId] ?? 0));
                      }
                    }
                    return iconContainer(
                      Icons.chat_bubble_outline,
                      theme.colorScheme.primary,
                      badgeCount: unreadCount,
                      onTap: () {
                        if (FirebaseAuth.instance.currentUser != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatsListScreen()),
                          );
                        } else {
                          Navigator.pushNamed(context, '/login');
                        }
                      },
                    );
                  },
                )
              : iconContainer(
                  Icons.chat_bubble_outline,
                  theme.colorScheme.primary,
                  onTap: () {
                    if (FirebaseAuth.instance.currentUser != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ChatsListScreen()),
                      );
                    } else {
                      Navigator.pushNamed(context, '/login');
                    }
                  },
                ),
          const SizedBox(width: 8),
          iconContainer(
            Icons.shopping_cart_outlined,
            theme.colorScheme.primary,
            badgeCount: globalCartItems.fold(
              0,
              (sum, item) => sum + item.quantity,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CartScreen()),
              ).then((_) => setState(() {}));
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children:
                  categories.map((category) {
                    final isSelected = category == selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.surface,
                          foregroundColor:
                              isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.textTheme.bodyLarge!.color,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            selectedCategory = category;
                          });
                        },

                        child: Text(
                            category[0].toUpperCase() + category.substring(1),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Product>>(
              future: futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: theme.colorScheme.primary,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }

                final allProducts = snapshot.data!;
                final filtered = filterByCategory(
                  allProducts,
                  selectedCategory,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final screenWidth = constraints.maxWidth;
                    const itemWidth = 180;
                    final crossAxisCount = (screenWidth / itemWidth)
                        .floor()
                        .clamp(1, 2);

                    return GridView.builder(
                      key: ValueKey(selectedCategory),
                      padding: const EdgeInsets.all(12),
                      itemCount: filtered.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        mainAxisExtent: 300,
                      ),
                      itemBuilder: (context, index) {
                        final product = filtered[index];
                        final cardData = convertProductToCard(product);

                        return Cards(
                          data: cardData,
                          favFunction: () async {
                            await loadFavorites();
                            setState(() {});
                          },
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        ProductDetailsScreen(data: cardData),
                              ),
                            );
                          },
                          onCartTap: () {
                            final index = globalCartItems.indexWhere(
                              (item) => item.id == cardData.id,
                            );
                            if (index != -1) {
                              globalCartItems[index].quantity++;
                            } else {
                              globalCartItems.add(
                                CardData(
                                  id: cardData.id,
                                  rate: cardData.rate,
                                  image: cardData.image,
                                  title: cardData.title,
                                  description: cardData.description,
                                  weight: cardData.weight,
                                  price: cardData.price,
                                  isFavorite: cardData.isFavorite,
                                  quantity: 1,
                                ),
                              );
                            }
                            setState(() {});
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget iconContainer(
    IconData icon,
    Color color, {
    VoidCallback? onTap,
    int badgeCount = 0,
  }) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: theme.dividerColor),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(icon, size: 18),
            color: color,
            onPressed: onTap,
          ),
        ),
        if (badgeCount > 0)
          Positioned(
            right: 2,
            top: 2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                '$badgeCount',
                style: TextStyle(
                  color: theme.colorScheme.onError,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
