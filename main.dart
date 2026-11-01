import 'package:flutter/material.dart';
import 'pos_database.dart';

void main() {
  runApp(const CounterApp());
}

const _ink = Color(0xFF202923);
const _muted = Color(0xFF778078);
const _green = Color(0xFFD6342B);
const _mint = Color(0xFFFFE99A);
const _paper = Color(0xFFFFF1B8);
const _surface = Color(0xFFFFFBE8);
const _line = Color(0xFFE7D88A);
const _coral = Color(0xFFC72D25);
const _gold = Color(0xFFC89100);
const _blue = Color(0xFF2186A8);
const _orange = Color(0xFFEE8A2E);
const _aqua = Color(0xFF3BAEAE);

Color _categoryAccent(String category) => switch (category) {
  'Bakery' => _orange,
  'Flowers' => const Color(0xFFD84C78),
  'Pantry' => _gold,
  'Water' => _blue,
  'Vegetables' => _aqua,
  _ => _green,
};

String _formatUgx(double amount) {
  final wholeAmount = amount.round().toString();
  final groupedAmount = wholeAmount.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => ',',
  );
  return 'UGX $groupedAmount';
}

class CounterApp extends StatelessWidget {
  const CounterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FreshBuy POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: _paper,
        colorScheme: ColorScheme.fromSeed(
          seedColor: _green,
          surface: _surface,
          onSurface: _ink,
        ),
        fontFamily: 'sans-serif',
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          elevation: 0,
        ),
      ),
      home: const PosHome(),
    );
  }
}

class Product {
  Product({
    this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.stock,
    required this.emoji,
    required this.color,
  });

  int? id;
  final String name;
  final String category;
  final double price;
  int stock;
  final String emoji;
  final Color color;
}

class Customer {
  Customer({this.id, required this.name, required this.email, required this.spent});

  int? id;
  final String name;
  final String email;
  final double spent;
}

class Sale {
  Sale({required this.total, required this.payment, required this.time});

  final double total;
  final String payment;
  final DateTime time;
}

class PosHome extends StatefulWidget {
  const PosHome({super.key});

  @override
  State<PosHome> createState() => _PosHomeState();
}

class _PosHomeState extends State<PosHome> {
  final PosDatabase _database = PosDatabase();
  bool _isLoading = true;
  int _tab = 0;
  bool _offline = false;
  String _storeName = 'FreshBuy';
  String _category = 'All items';
  final Map<Product, int> _cart = {};
  final List<Sale> _sales = [
    Sale(total: 24500, payment: 'Card', time: DateTime.now()),
    Sale(total: 16000, payment: 'Cash', time: DateTime.now()),
    Sale(total: 38750, payment: 'Mobile', time: DateTime.now()),
  ];
  final List<Product> _products = [
    Product(
      name: 'Fresh bread',
      category: 'Bakery',
      price: 8000,
      stock: 24,
      emoji: '🍞',
      color: const Color(0xFFFFD591),
    ),
    Product(
      name: 'Market flowers',
      category: 'Flowers',
      price: 18000,
      stock: 8,
      emoji: '💐',
      color: const Color(0xFFFFC5D3),
    ),
    Product(
      name: 'Sugar',
      category: 'Pantry',
      price: 5500,
      stock: 18,
      emoji: '🧂',
      color: const Color(0xFFFFE4A8),
    ),
    Product(
      name: 'Rwenzori water',
      category: 'Water',
      price: 2000,
      stock: 30,
      emoji: '💧',
      color: const Color(0xFFBFE8F6),
    ),
    Product(
      name: 'Yacket water',
      category: 'Water',
      price: 1000,
      stock: 36,
      emoji: '💧',
      color: const Color(0xFFCAE8F1),
    ),
    Product(
      name: 'Carrots',
      category: 'Vegetables',
      price: 3000,
      stock: 16,
      emoji: '🥕',
      color: const Color(0xFFFFC58C),
    ),
    Product(
      name: 'Tomatoes',
      category: 'Vegetables',
      price: 2500,
      stock: 14,
      emoji: '🍅',
      color: const Color(0xFFFFB3A4),
    ),
  ];
  final List<Customer> _customers = [
    Customer(
      name: 'Namiro Zainah',
      email: 'namiro.z@gmail.com',
      spent: 284500,
    ),
    Customer(name: 'Kato Jerome', email: 'kato.j@gmail.com', spent: 156000),
    Customer(name: 'Ashanti Ada', email: 'ashanti.a@gmail.com', spent: 92750),
  ];

  double get _cartTotal => _cart.entries.fold(
    0,
    (total, entry) => total + entry.key.price * entry.value,
  );

  int get _cartCount => _cart.values.fold(0, (total, count) => total + count);

  double get _todaySales =>
      1248500 + _sales.fold(0, (total, sale) => total + sale.total);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    await _database.seedIfEmpty(
      products: _products.map(_productToRow).toList(),
      customers: _customers.map(_customerToRow).toList(),
      sales: _sales.map(_saleToRow).toList(),
    );
    final products = await _database.loadProducts();
    final customers = await _database.loadCustomers();
    final sales = await _database.loadSales();
    final settings = await _database.loadSettings();
    if (!mounted) return;
    setState(() {
      _products
        ..clear()
        ..addAll(products.map(_productFromRow));
      _customers
        ..clear()
        ..addAll(customers.map(_customerFromRow));
      _sales
        ..clear()
        ..addAll(sales.map(_saleFromRow));
      _storeName = settings['store_name'] ?? _storeName;
      _offline = settings['offline'] == 'true';
      _isLoading = false;
    });
  }

  Map<String, Object?> _productToRow(Product product) => {
    'name': product.name,
    'category': product.category,
    'price': product.price,
    'stock': product.stock,
    'emoji': product.emoji,
    'color': product.color.toARGB32(),
  };

  Product _productFromRow(Map<String, Object?> row) => Product(
    id: row['id']! as int,
    name: row['name']! as String,
    category: row['category']! as String,
    price: (row['price']! as num).toDouble(),
    stock: row['stock']! as int,
    emoji: row['emoji']! as String,
    color: Color(row['color']! as int),
  );

  Map<String, Object?> _customerToRow(Customer customer) => {
    'name': customer.name,
    'email': customer.email,
    'spent': customer.spent,
  };

  Customer _customerFromRow(Map<String, Object?> row) => Customer(
    id: row['id']! as int,
    name: row['name']! as String,
    email: row['email']! as String,
    spent: (row['spent']! as num).toDouble(),
  );

  Map<String, Object?> _saleToRow(Sale sale) => {
    'total': sale.total,
    'payment': sale.payment,
    'time': sale.time.millisecondsSinceEpoch,
  };

  Sale _saleFromRow(Map<String, Object?> row) => Sale(
    total: (row['total']! as num).toDouble(),
    payment: row['payment']! as String,
    time: DateTime.fromMillisecondsSinceEpoch(row['time']! as int),
  );

  @override
  Widget build(BuildContext context) {
    final pages = [
      _overview(),
      _checkout(),
      _inventory(),
      _customersPage(),
      _reports(),
    ];

    return Scaffold(
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
          children: [
            _topBar(),
            Expanded(child: pages[_tab]),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (index) => setState(() => _tab = index),
        backgroundColor: _surface,
        indicatorColor: _mint,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.grid_view_outlined),
            selectedIcon: Icon(Icons.grid_view_rounded),
            label: 'Today',
          ),
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale_rounded),
            label: 'Sell',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory_2_rounded),
            label: 'Stock',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'People',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _topBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(13),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x337F5A00),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const Icon(
                  Icons.shopping_basket_rounded,
                  color: _green,
                  size: 29,
                ),
                Positioned(
                  top: 1,
                  left: 7,
                  child: Icon(
                    Icons.local_florist_rounded,
                    color: _coral,
                    size: 13,
                  ),
                ),
                Positioned(
                  top: 1,
                  right: 7,
                  child: Icon(
                    Icons.bakery_dining_rounded,
                    color: _gold,
                    size: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  const TextSpan(
                    children: [
                      TextSpan(
                        text: 'Fresh',
                        style: TextStyle(color: _coral),
                      ),
                      TextSpan(
                        text: 'Buy',
                        style: TextStyle(color: _gold),
                      ),
                    ],
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _offline
                      ? 'Offline · saved on this device'
                      : 'Register 01 · Online',
                  style: TextStyle(
                    color: _offline ? _coral : _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: _offline ? 'Go online' : 'Go offline',
            onPressed: () async {
              final offline = !_offline;
              await _database.saveSetting('offline', '$offline');
              if (mounted) setState(() => _offline = offline);
            },
            icon: Icon(
              _offline ? Icons.cloud_off_outlined : Icons.cloud_done_outlined,
              color: _offline ? _coral : _green,
            ),
          ),
          IconButton(
            tooltip: 'Store settings',
            onPressed: _showSettings,
            icon: const Icon(Icons.tune_rounded, color: _ink),
          ),
        ],
      ),
    );
  }

  Widget _overview() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _salesSummary(),
        const SizedBox(height: 9),
        const Row(
          children: [
            Icon(Icons.calendar_today_rounded, color: _coral, size: 15),
            SizedBox(width: 7),
            Text(
              'Tuesday, October 27',
              style: TextStyle(
                color: _muted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _metricCard(
                'Transactions',
                '${12 + _sales.length}',
                '+ 3 from yesterday',
                Icons.receipt_long_outlined,
                const Color(0xFFDDF2F8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _metricCard(
                'Average sale',
                _formatUgx(_todaySales / (12 + _sales.length)),
                'Across all payments',
                Icons.trending_up_rounded,
                const Color(0xFFFFDDD6),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle(
          'Recent activity',
          action: 'View all',
          onTap: () => setState(() => _tab = 4),
        ),
        const SizedBox(height: 10),
        ..._sales.reversed.take(3).map(_saleRow),
        const SizedBox(height: 22),
        _sectionTitle(
          'Running low',
          action: 'Manage stock',
          onTap: () => setState(() => _tab = 2),
        ),
        const SizedBox(height: 10),
        ..._products
            .where((product) => product.stock <= 6)
            .take(3)
            .map(_stockRow),
      ],
    );
  }

  Widget _salesSummary() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'NET SALES · TODAY',
                  style: TextStyle(
                    color: Color(0xFFFFE99A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '+12.8%',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _formatUgx(_todaySales),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: CustomPaint(painter: _SparklinePainter()),
          ),
          const SizedBox(height: 5),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '8 AM',
                style: TextStyle(color: Color(0xFFFFE99A), fontSize: 10),
              ),
              Text(
                '12 PM',
                style: TextStyle(color: Color(0xFFFFE99A), fontSize: 10),
              ),
              Text(
                '4 PM',
                style: TextStyle(color: Color(0xFFFFE99A), fontSize: 10),
              ),
              Text(
                'Now',
                style: TextStyle(color: Color(0xFFFFE99A), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricCard(
    String title,
    String value,
    String note,
    IconData icon,
    Color tint,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: tint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _green),
          ),
          const SizedBox(height: 13),
          Text(title, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            note,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _checkout() {
    final categories = [
      'All items',
      ..._products.map((product) => product.category).toSet(),
    ];
    final filtered = _category == 'All items'
        ? _products
        : _products.where((product) => product.category == _category).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _pageHeading('New sale', 'Tap an item to add it to the order'),
              const SizedBox(height: 14),
              SizedBox(
                height: 37,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final category = categories[index];
                    final selected = _category == category;
                    final accent = _categoryAccent(category);
                    return ChoiceChip(
                      label: Text(category),
                      selected: selected,
                      onSelected: (_) => setState(() => _category = category),
                      showCheckmark: false,
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      backgroundColor: accent.withValues(alpha: 0.12),
                      selectedColor: accent,
                      side: BorderSide(
                        color: selected
                            ? accent
                            : accent.withValues(alpha: 0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            itemCount: filtered.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 145,
            ),
            itemBuilder: (context, index) => _productCard(filtered[index]),
          ),
        ),
        if (_cart.isNotEmpty) _cartBar(),
      ],
    );
  }

  Widget _productCard(Product product) {
    final count = _cart[product] ?? 0;
    return Material(
      color: _surface,
      borderRadius: BorderRadius.circular(15),
      child: InkWell(
        onTap: product.stock > count ? () => _changeCart(product, 1) : null,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: product.color,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x337F5A00),
                          blurRadius: 5,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      product.emoji,
                      style: const TextStyle(fontSize: 23),
                    ),
                  ),
                  const Spacer(),
                  if (count > 0)
                    Container(
                      width: 23,
                      height: 23,
                      decoration: const BoxDecoration(
                        color: _green,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                product.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatUgx(product.price),
                      style: const TextStyle(
                        color: _green,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    '${product.stock} left',
                    style: TextStyle(
                      color: product.stock <= 5 ? _coral : _muted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _cartBar() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
        child: SizedBox(
          height: 54,
          child: FilledButton(
            onPressed: _showCart,
            style: FilledButton.styleFrom(
              backgroundColor: _ink,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_basket_outlined, size: 19),
                const SizedBox(width: 9),
                Text(
                  '$_cartCount items',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  _formatUgx(_cartTotal),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeCart(Product product, int delta) {
    setState(() {
      final nextCount = (_cart[product] ?? 0) + delta;
      if (nextCount <= 0) {
        _cart.remove(product);
      } else if (nextCount <= product.stock) {
        _cart[product] = nextCount;
      }
    });
  }

  Future<void> _showCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, refreshSheet) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            14,
            20,
            MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 38,
                    height: 4,
                    decoration: BoxDecoration(
                      color: _line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Current order',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '$_cartCount items',
                      style: const TextStyle(color: _muted, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ..._cart.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.key.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            _changeCart(entry.key, -1);
                            refreshSheet(() {});
                          },
                          icon: const Icon(Icons.remove_circle_outline),
                          visualDensity: VisualDensity.compact,
                        ),
                        Text(
                          '${entry.value}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        IconButton(
                          onPressed: () {
                            _changeCart(entry.key, 1);
                            refreshSheet(() {});
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          visualDensity: VisualDensity.compact,
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            _formatUgx(entry.key.price * entry.value),
                            textAlign: TextAlign.right,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Divider(height: 22),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      _formatUgx(_cartTotal),
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: _cart.isEmpty
                        ? null
                        : () {
                            Navigator.pop(context);
                            _showPayment();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Continue to payment'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showPayment() async {
    String payment = 'Card';
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, refreshSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment method',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose how this customer is paying.',
                  style: TextStyle(color: _muted, fontSize: 13),
                ),
                const SizedBox(height: 16),
                RadioGroup<String>(
                  groupValue: payment,
                  onChanged: (value) {
                    if (value != null) refreshSheet(() => payment = value);
                  },
                  child: Column(
                    children: [
                      for (final option in [
                        ('Cash', Icons.payments_outlined),
                        ('Card', Icons.credit_card_outlined),
                        ('Mobile', Icons.phone_iphone_outlined),
                      ])
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(
                            option.$2,
                            color: payment == option.$1 ? _green : _muted,
                          ),
                          title: Text(
                            option.$1,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          trailing: Radio<String>(value: option.$1),
                          onTap: () => refreshSheet(() => payment = option.$1),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    onPressed: () => _completeSale(payment),
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text('Record ${_formatUgx(_cartTotal)} sale'),
                  ),
                ),
                const SizedBox(height: 9),
                const Center(
                  child: Text(
                    'Card and mobile payments require a connected provider.',
                    style: TextStyle(color: _muted, fontSize: 10),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _completeSale(String payment) async {
    final total = _cartTotal;
    final stockChanges = {
      for (final entry in _cart.entries) entry.key.id!: entry.value,
    };
    final time = DateTime.now();
    await _database.recordSale(
      total: total,
      payment: payment,
      time: time,
      stockChanges: stockChanges,
    );
    if (!mounted) return;
    setState(() {
      for (final entry in _cart.entries) {
        entry.key.stock -= entry.value;
      }
      _sales.add(Sale(total: total, payment: payment, time: time));
      _cart.clear();
    });
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sale recorded · ${_formatUgx(total)} via $payment'),
      ),
    );
  }

  Widget _inventory() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Inventory',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Add product',
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_products.length} products · ${_products.fold<int>(0, (sum, product) => sum + product.stock)} units on hand',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 18),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFFE99A),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _coral),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${_products.where((product) => product.stock <= 5).length} products need restocking',
                  style: const TextStyle(
                    color: _ink,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: _coral,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ..._products.map(_inventoryRow),
      ],
    );
  }

  Widget _inventoryRow(Product product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: product.color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x337F5A00),
                  blurRadius: 5,
                  offset: Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 25)),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${product.category} · ${_formatUgx(product.price)}',
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: product.stock > 0
                ? () async {
                    final stock = product.stock - 1;
                    await _database.updateProductStock(product.id!, stock);
                    if (mounted) setState(() => product.stock = stock);
                  }
                : null,
            icon: const Icon(Icons.remove_rounded),
            visualDensity: VisualDensity.compact,
          ),
          SizedBox(
            width: 25,
            child: Text(
              '${product.stock}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: product.stock <= 5 ? _coral : _ink,
              ),
            ),
          ),
          IconButton(
            onPressed: () async {
              final stock = product.stock + 1;
              await _database.updateProductStock(product.id!, stock);
              if (mounted) setState(() => product.stock = stock);
            },
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct() async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '1');
    final formKey = GlobalKey<FormState>();
    final productData = await showDialog<(String, double, int)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add product'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              TextFormField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'Price'),
                validator: (value) => double.tryParse(value ?? '') == null
                    ? 'Enter a valid price'
                    : null,
              ),
              TextFormField(
                controller: stockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Starting stock'),
                validator: (value) => int.tryParse(value ?? '') == null
                    ? 'Enter a whole number'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, (
                  nameController.text.trim(),
                  double.parse(priceController.text),
                  int.parse(stockController.text),
                ));
              }
            },
            child: const Text('Add product'),
          ),
        ],
      ),
    );
    nameController.dispose();
    priceController.dispose();
    stockController.dispose();
    if (productData != null) {
      final product = Product(
        name: productData.$1,
        category: 'Goods',
        price: productData.$2,
        stock: productData.$3,
        emoji: '📦',
        color: const Color(0xFFE8E8DA),
      );
      product.id = await _database.insertProduct(_productToRow(product));
      if (!mounted) return;
      setState(
        () => _products.add(product),
      );
    }
  }

  Widget _customersPage() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Customers',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Add customer',
              onPressed: _addCustomer,
              icon: const Icon(Icons.person_add_alt_1_rounded),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_customers.length} returning customers',
          style: const TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            hintText: 'Search customers',
            prefixIcon: const Icon(Icons.search_rounded, color: _muted),
            filled: true,
            fillColor: _surface,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(13),
              borderSide: const BorderSide(color: _line),
            ),
          ),
          onChanged: (query) => setState(() => _customerQuery = query),
        ),
        const SizedBox(height: 14),
        ..._customers
            .where(
              (customer) =>
                  customer.name.toLowerCase().contains(
                    _customerQuery.toLowerCase(),
                  ) ||
                  customer.email.toLowerCase().contains(
                    _customerQuery.toLowerCase(),
                  ),
            )
            .map(_customerRow),
      ],
    );
  }

  String _customerQuery = '';

  Widget _customerRow(Customer customer) {
    final initials = customer.name
        .split(' ')
        .map((part) => part[0])
        .take(2)
        .join();
    final avatarColors = [_blue, _orange, _aqua];
    final accent =
        avatarColors[_customers.indexOf(customer) % avatarColors.length];
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: accent.withValues(alpha: 0.16),
            child: Text(
              initials,
              style: TextStyle(
                color: accent,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  customer.email,
                  style: const TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'LIFETIME',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _formatUgx(customer.spent),
                style: const TextStyle(
                  color: _ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _addCustomer() async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final customerData = await showDialog<(String, String)>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add customer'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter a name'
                    : null,
              ),
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => RegExp(
                  r'^[^@\s]+@gmail\.com$',
                  caseSensitive: false,
                ).hasMatch(value?.trim() ?? '')
                    ? null
                    : 'Enter a valid Gmail address',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, (
                  nameController.text.trim(),
                  emailController.text.trim(),
                ));
              }
            },
            child: const Text('Add customer'),
          ),
        ],
      ),
    );
    nameController.dispose();
    emailController.dispose();
    if (customerData != null) {
      final customer = Customer(
        name: customerData.$1,
        email: customerData.$2,
        spent: 0,
      );
      customer.id = await _database.insertCustomer(_customerToRow(customer));
      if (!mounted) return;
      setState(
        () => _customers.add(customer),
      );
    }
  }

  Widget _reports() {
    final paymentTotals = <String, double>{'Cash': 0, 'Card': 0, 'Mobile': 0};
    for (final sale in _sales) {
      paymentTotals[sale.payment] =
          (paymentTotals[sale.payment] ?? 0) + sale.total;
    }
    final grandTotal = paymentTotals.values.fold<double>(
      0,
      (sum, value) => sum + value,
    );

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      children: [
        _pageHeading('Reports', 'A clear view of how your store is doing'),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _surface,
            border: Border.all(color: _line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sales this week',
                style: TextStyle(color: _muted, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                _formatUgx(_todaySales * 4.8),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 140,
                child: CustomPaint(
                  painter: _BarChartPainter(),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 9),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Mon', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Tue', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Wed', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Thu', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Fri', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Sat', style: TextStyle(color: _muted, fontSize: 10)),
                  Text('Sun', style: TextStyle(color: _muted, fontSize: 10)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _sectionTitle('Payment breakdown'),
        const SizedBox(height: 10),
        for (final item in paymentTotals.entries)
          _paymentBreakdown(item.key, item.value, grandTotal),
        const SizedBox(height: 12),
        _sectionTitle('Latest sales'),
        const SizedBox(height: 8),
        ..._sales.reversed.take(6).map(_saleRow),
      ],
    );
  }

  Widget _paymentBreakdown(String name, double amount, double total) {
    final ratio = total == 0 ? 0.0 : amount / total;
    final accent = name == 'Cash'
        ? _gold
        : name == 'Card'
        ? _green
        : _blue;
    final icon = name == 'Cash'
        ? Icons.payments_outlined
        : name == 'Card'
        ? Icons.credit_card_outlined
        : Icons.phone_iphone_outlined;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: _surface,
              border: Border.all(color: _line),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: accent),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 50,
            child: Text(
              name,
              style: const TextStyle(
                color: _ink,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: ratio,
                minHeight: 6,
                backgroundColor: _line,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 78,
            child: Text(
              _formatUgx(amount),
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _saleRow(Sale sale) {
    final icon = sale.payment == 'Cash'
        ? Icons.payments_outlined
        : sale.payment == 'Card'
        ? Icons.credit_card_outlined
        : Icons.phone_iphone_outlined;
    final time = TimeOfDay.fromDateTime(sale.time).format(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: _surface,
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _mint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _green),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${sale.payment} payment',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(time, style: const TextStyle(color: _muted, fontSize: 10)),
              ],
            ),
          ),
          Text(
            _formatUgx(sale.total),
            style: const TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stockRow(Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Container(
            width: 33,
            height: 33,
            decoration: BoxDecoration(
              color: product.color,
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Text(product.emoji, style: const TextStyle(fontSize: 21)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              product.name,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${product.stock} left',
            style: TextStyle(
              color: product.stock <= 4 ? _coral : _muted,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageHeading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 25,
            fontWeight: FontWeight.w700,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 5),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 12)),
      ],
    );
  }

  Widget _sectionTitle(String title, {String? action, VoidCallback? onTap}) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: _ink,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              action,
              style: const TextStyle(
                color: _green,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _showSettings() async {
    final nameController = TextEditingController(text: _storeName);
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Store name'),
            ),
            const SizedBox(height: 14),
            const Text(
              'Tax and payment provider settings can be connected for your business.',
              style: TextStyle(color: _muted, fontSize: 12),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.cloud_off_outlined, color: _coral, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _offline ? 'Offline mode is on' : 'Offline mode is off',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, nameController.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    nameController.dispose();
    if (name != null && name.isNotEmpty) {
      await _database.saveSetting('store_name', name);
      if (mounted) setState(() => _storeName = name);
    }
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [
      0.78,
      0.62,
      0.68,
      0.40,
      0.52,
      0.36,
      0.47,
      0.24,
      0.38,
      0.29,
      0.42,
      0.15,
    ];
    final points = [
      for (var index = 0; index < values.length; index++)
        Offset(
          size.width * index / (values.length - 1),
          size.height * values[index],
        ),
    ];
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (final point in points.skip(1)) {
      path.lineTo(point.dx, point.dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = const Color(0xFFFFE99A)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawCircle(points.last, 4, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _BarChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const values = [0.46, 0.72, 0.58, 0.84, 0.64, 0.92, 0.54];
    const barColors = [_blue, _aqua, _coral, _orange, _gold, _green, _blue];
    final barWidth = size.width / 13;
    final gap = (size.width - values.length * barWidth) / (values.length * 2);
    for (var index = 0; index < values.length; index++) {
      final height = size.height * values[index];
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          gap + index * (barWidth + 2 * gap),
          size.height - height,
          barWidth,
          height,
        ),
        const Radius.circular(5),
      );
      canvas.drawRRect(rect, Paint()..color = barColors[index]);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
