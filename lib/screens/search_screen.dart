import 'package:flutter/material.dart';
import 'package:petut/Data/Product.dart';
import 'package:petut/Common/cards.dart';
import 'package:petut/Data/fetchProducts.dart';
import 'package:petut/app_colors.dart';
import 'package:petut/Data/card_data.dart';

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
    setState(() {
      _allProducts = products;
      _isLoading = false;
    });
  }

  void _filterProducts(String query) {
    final filtered = _allProducts.where((product) {
      return product.name.toLowerCase().contains(query.toLowerCase());
    }).toList();

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
      price: product.price.toInt(),
      rate: product.rate,
      weight: double.tryParse(product.weight.replaceAll("g", "")) != null
          ? double.parse(product.weight.replaceAll("g", "")) / 1000
          : 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: AppColors.background,
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Search products...',
            border: InputBorder.none,
          ),
          onChanged: _filterProducts,
          autofocus: true,
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : _searchQuery.isEmpty
              ? const Center(
                  child: Text(
                    "Let's find something",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: AppColors.gray,
                    ),
                  ),
                )
              : _filteredProducts.isEmpty
                  ? const Center(
                      child: Text(
                        'No products found',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.gray,
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
                          ),
                        );
                      },
                    ),
    );
  }
}
