import 'package:flutter/material.dart';
import 'package:petut/Data/Product.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/fetchProducts.dart';
import 'package:petut/Data/card_data.dart';
import 'package:petut/Data/globelCartItem.dart';
import 'package:petut/screens/product_details_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Product> _allProducts = [];
  List<Product> _filteredProducts = [];
  String _searchQuery = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    loadProducts();
  }

  Future<void> loadProducts() async {
    final products = await fetchProducts();
    if (mounted) {
      setState(() {
        _allProducts = products;
        _isLoading = false;
      });
    }
  }

  void _filterProducts(String query) {
    final filtered =
        _allProducts
            .where(
              (product) =>
                  product.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();

    setState(() {
      _searchQuery = query;
      _filteredProducts = filtered;
    });
  }

  CardData convertProductToCard(Product product) {
    return CardData(
      id: product.id,
      title: product.name,
      description: product.details,
      image: product.image,
      price: product.price,
      rate: product.rate,
      weight:
          product.weight.replaceAll("g", "")
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        iconTheme: theme.iconTheme,
        title: TextField(
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: theme.hintColor,
            ),
            border: InputBorder.none,
          ),
          onChanged: _filterProducts,
          autofocus: true,
        ),
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
              : _searchQuery.isEmpty
              ? Center(
                child: Text(
                  "Let's find something",
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: theme.hintColor,
                  ),
                ),
              )
              : _filteredProducts.isEmpty
              ? Center(
                child: Text(
                  'No products found',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.hintColor,
                  ),
                ),
              )
              : ListView.builder(
                itemCount: _filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = _filteredProducts[index];
                  final cardData = convertProductToCard(product);

                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Cards(
                      data: cardData,
                      favFunction: () {
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
                        final indexInCart = globalCartItems.indexWhere(
                          (item) => item.id == cardData.id,
                        );

                        if (indexInCart >= 0) {
                          globalCartItems[indexInCart].quantity++;
                        } else {
                          globalCartItems.add(
                            CardData(
                              id: cardData.id,
                              title: cardData.title,
                              description: cardData.description,
                              image: cardData.image,
                              price: cardData.price,
                              weight: cardData.weight,
                              rate: cardData.rate,
                              isFavorite: cardData.isFavorite,
                              quantity: 1,
                            ),
                          );
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Added to cart")),
                        );
                      },
                    ),
                  );
                },
              ),
    );
  }
}
