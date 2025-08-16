import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  String getCategoryImage(String category) {
    switch (category.toLowerCase()) {
      case 'all':
        return 'assets/images/petut.png';
      case 'cat':
        return 'assets/cattt.jpg';
      case 'dog':
        return 'assets/dogg.jpg';
      case 'bird':
        return 'assets/birdd.jpg';
      case 'toys':
        return 'assets/toyy.jpg';
      default:
        return 'assets/images/petut.png';
    }
  }

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
      category: product.category,

      isFavorite: favoriteIds.contains(product.id.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false, // يمنع الباك الطبيعي
      onPopInvoked: (didPop) async {
        // هنا بقى نتحكم في الباك
        final shouldExit = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
                title: Text('Do You want to Leave ?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: Text('No'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: Text('Yes'),
                  ),
                ],
              ),
        );

        if (shouldExit == true) {
          SystemNavigator.pop(); // يخرج من التطبيق
        }
      },
      child: Scaffold(
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
                      final currentUserId =
                          FirebaseAuth.instance.currentUser?.uid;
                      if (currentUserId != null) {
                        unreadCount = snapshot.data!.fold(
                          0,
                          (sum, chat) =>
                              sum + (chat.unreadCount[currentUserId] ?? 0),
                        );
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
                            MaterialPageRoute(
                              builder: (_) => const ChatsListScreen(),
                            ),
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
                        MaterialPageRoute(
                          builder: (_) => const ChatsListScreen(),
                        ),
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
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: false,
              automaticallyImplyLeading: false,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      children: [
                        Image.network(
                          'https://readdy.ai/api/search-image?query=Happy%20golden%20retriever%20and%20persian%20cat%20playing%20together%20in%20a%20bright%20veterinary%20clinic%20with%20modern%20equipment%2C%20soft%20natural%20lighting%2C%20clean%20white%20background%20with%20plants%2C%20professional%20pet%20care%20atmosphere%2C%20warm%20and%20welcoming%20environment%20with%20medical%20tools%20visible%20in%20background&width=1920&height=1080&seq=hero-bg&orientation=landscape',
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: double.infinity,
                              height: 180,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: double.infinity,
                              height: 180,
                              color: Theme.of(
                                context,
                              ).colorScheme.primary.withOpacity(0.1),
                              child: Icon(
                                Icons.pets,
                                size: 50,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            );
                          },
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withOpacity(0.5),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 16,
                          top: 0,
                          bottom: 0,
                          right: 100,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Premium Care for\nYour Beloved Pets',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Professional veterinary services with 24/7 care',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white.withOpacity(0.9),
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children:
                      categories.map((category) {
                        final isSelected = category == selectedCategory;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedCategory = category;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isSelected
                                      ? theme.colorScheme.primary.withOpacity(
                                        0.2,
                                      )
                                      : Colors.transparent, // ← هنا التغيير
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color:
                                    isSelected
                                        ? theme.colorScheme.primary
                                        : Colors.grey.shade300,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.asset(
                                    getCategoryImage(category),
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: theme.colorScheme.primary
                                            .withOpacity(0.1),
                                        child: Icon(
                                          Icons.pets,
                                          size: 20,
                                          color: theme.colorScheme.primary,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  category[0].toUpperCase() +
                                      category.substring(1),
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight:
                                        isSelected
                                            ? FontWeight.bold
                                            : FontWeight.w500,
                                    color:
                                        isSelected
                                            ? theme.colorScheme.primary
                                            : theme.textTheme.bodyMedium!.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
            ),

            FutureBuilder<List<Product>>(
              future: futureProducts,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  );
                } else if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(child: Text("Error: ${snapshot.error}")),
                  );
                }

                final allProducts = snapshot.data!;
                final filtered = filterByCategory(
                  allProducts,
                  selectedCategory,
                );

                return SliverGrid(
                  delegate: SliverChildBuilderDelegate((context, index) {
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
                              category: cardData.category,
                            ),
                          );
                        }
                        setState(() {});
                      },
                    );
                  }, childCount: filtered.length),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    // mainAxisExtent: 300,
                    childAspectRatio: 0.75
                  ),
                );
              },
            ),
          ],
        ),
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
