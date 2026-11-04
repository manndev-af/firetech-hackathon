import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const Color primary = Color(0xFF829B35);
  static const Color background = Color(0xFFF8F8F5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              _buildHeader(),

              const SizedBox(height: 30),

              // ORDERS
              _buildSectionHeader(
                title: 'Orders',
                action: 'Go to Orders',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              _buildOrders(),

              const SizedBox(height: 28),

              // INVENTORY
              _buildSectionHeader(
                title: 'Inventory',
                action: 'Go to Inventory',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              _buildInventory(),

              const SizedBox(height: 28),

              // MENU
              _buildSectionHeader(
                title: 'Menu',
                action: 'Go to Menu',
                onTap: () {},
              ),

              const SizedBox(height: 14),

              _buildMenu(),
            ],
          ),
        ),
      ),
    );
  }

  // HEADER
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: const BoxDecoration(
            color: primary,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restaurant, color: Colors.white, size: 26),
        ),

        const SizedBox(width: 12),

        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Maria's Kitchen",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF202020),
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Cookstro',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),

        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(Icons.notifications_none_rounded, size: 24),
              Positioned(
                top: 9,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SECTION HEADER
  Widget _buildSectionHeader({
    required String title,
    required String action,
    required VoidCallback onTap,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
        ),

        GestureDetector(
          onTap: onTap,
          child: Text(
            action,
            style: const TextStyle(
              color: primary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  // ORDERS
  Widget _buildOrders() {
    final orders = [
      {
        'number': '34621',
        'time': 'Mon 11:00 am - 11:15 am',
        'icon': Icons.access_time,
      },
      {
        'number': '34622',
        'time': 'Mon 11:00 am - 11:15 am',
        'icon': Icons.room_service_outlined,
      },
    ];

    return SizedBox(
      height: 126,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final order = orders[index];

          return Container(
            width: 250,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '№ ${order['number']}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const Spacer(),
                    Icon(order['icon'] as IconData, color: primary, size: 20),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  order['time'] as String,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),

                const Spacer(),

                Row(
                  children: [
                    _orderFoodImage(
                      'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=120',
                    ),
                    const SizedBox(width: 7),
                    _orderFoodImage(
                      'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=120',
                    ),
                    const SizedBox(width: 7),
                    _orderFoodImage(
                      'https://images.unsplash.com/photo-1550547660-d9450f859349?w=120',
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _orderFoodImage(String image) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Image.network(
        image,
        width: 43,
        height: 38,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          width: 43,
          height: 38,
          color: Colors.grey.shade200,
          child: const Icon(Icons.restaurant, size: 18),
        ),
      ),
    );
  }

  // INVENTORY
  Widget _buildInventory() {
    final items = [
      {
        'name': 'Classic Burger',
        'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
        'stock': '23/25',
        'calories': '450',
        'price': '14',
      },
      {
        'name': 'Meat Grill',
        'image':
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500',
        'stock': '23/25',
        'calories': '450',
        'price': '18',
      },
      {
        'name': 'Chicken Steak',
        'image': 'https://images.unsplash.com/photo-1532550907401-a500c9a57435?w=500',
        'stock': '18/25',
        'calories': '380',
        'price': '16',
      },
      {
        'name': 'Beef Steak',
        'image': 'https://images.unsplash.com/photo-1600891964092-4316c288032e?w=500',
        'stock': '15/20',
        'calories': '520',
        'price': '22',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        mainAxisExtent: 295,
      ),
      itemBuilder: (context, index) {
        final item = items[index];

        return _buildFoodCard(item);
      },
    );
  }

  Widget _buildFoodCard(Map<String, String> item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Food image
          Stack(
            children: [
              Image.network(
                item['image']!,
                height: 145,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 145,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.restaurant, size: 40),
                ),
              ),

              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite,
                    color: Color(0xFFE76B62),
                    size: 18,
                  ),
                ),
              ),

              Positioned(
                bottom: 10,
                right: 10,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item['stock']!,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Food information
          Padding(
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['name']!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Color(0xFFE77955),
                      size: 16,
                    ),
                    Text(
                      ' ${item['calories']} cal',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 7),

                const Text(
                  'Homemade beef cutlet with signature sauce...',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.4,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Text(
                      '\$${item['price']}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.deepOrange,
                      size: 15,
                    ),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.grey,
                      size: 15,
                    ),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.grey,
                      size: 15,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // MENU
  Widget _buildMenu() {
    final menus = [
      {
        'name': 'Classic Burger',
        'price': '\$14',
        'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=500',
      },
      {
        'name': 'Meat Grill',
        'price': '\$18',
        'image':
            'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=500',
      },
    ];

    return SizedBox(
      height: 130,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: menus.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final menu = menus[index];

          return Container(
            width: 230,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    menu['image']!,
                    width: 90,
                    height: 105,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 90,
                      height: 105,
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.restaurant),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        menu['name']!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        menu['price']!,
                        style: const TextStyle(
                          color: primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
