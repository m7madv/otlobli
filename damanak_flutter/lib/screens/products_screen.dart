import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/account.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'product_form_screen.dart';
import 'scanner_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addProduct() async {
    await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
    );
  }

  Future<void> _scan() async {
    final code = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => const ScannerScreen(returnBarcode: true),
      ),
    );
    if (code == null || !mounted) return;
    final product = AppScope.of(context).productByBarcode(code);
    if (product != null) {
      await _editProduct(product);
    } else {
      await Navigator.of(context).push<Product>(
        MaterialPageRoute(
          builder: (_) => ProductFormScreen(initialBarcode: code),
        ),
      );
    }
  }

  Future<void> _editProduct(Product product) async {
    await Navigator.of(context).push<Product>(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Future<void> _archiveProduct(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('أرشفة المنتج؟'),
        content: const Text(
          'سيختفي المنتج من الكتالوج والمسح، وستبقى الضمانات السابقة محفوظة.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('أرشفة المنتج'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await AppScope.of(context).updateProduct(
      productId: product.id,
      name: product.name,
      brand: product.brand,
      category: product.category,
      barcode: product.barcode,
      sku: product.sku,
      warrantyMonths: product.warrantyMonths,
      salePrice: product.salePrice,
      costPrice: product.costPrice,
      trackInventory: product.trackInventory,
      isSerialized: product.isSerialized,
      reorderPoint: product.reorderPoint,
      isActive: false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context);
    final colors = context.colors;
    final canManage = controller.membership!.role.canManageTeam;
    final products = controller.products
        .where((item) => item.matches(_search.text))
        .toList();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: _addProduct,
              icon: const Icon(Icons.add_rounded),
              label: const Text('منتج جديد'),
            )
          : null,
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980),
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(18, 22, 18, 10),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'المنتجات',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${controller.products.length} منتج • اضغط على أي منتج لتعديله',
                        style: TextStyle(
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const MessageBanner(),
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        textInputAction: TextInputAction.search,
                        decoration: InputDecoration(
                          hintText: 'اسم المنتج أو الباركود…',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: IconButton(
                            tooltip: 'مسح باركود',
                            onPressed: _scan,
                            icon: const Icon(Icons.qr_code_scanner_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (products.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.all(18),
                  sliver: SliverToBoxAdapter(
                    child: _EmptyProducts(
                      hasQuery: _search.text.isNotEmpty,
                      onAdd: canManage ? _addProduct : null,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                  sliver: SliverList.separated(
                    itemCount: products.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _ProductCard(
                      product: products[index],
                      available: controller
                          .inventoryLevel(products[index].id)
                          ?.available,
                      currencyCode: controller.store!.currencyCode,
                      onEdit: canManage
                          ? () => _editProduct(products[index])
                          : null,
                      onArchive: canManage
                          ? () => _archiveProduct(products[index])
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.product,
    required this.available,
    required this.currencyCode,
    required this.onEdit,
    required this.onArchive,
  });

  final Product product;
  final num? available;
  final String currencyCode;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 54,
                decoration: BoxDecoration(
                  color: colors.primaryContainer,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(Icons.inventory_2_outlined, color: colors.primary),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        product.brand,
                        product.category,
                        product.sku,
                      ].where((value) => value.isNotEmpty).join(' • '),
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 10,
                      runSpacing: 4,
                      children: [
                        Text(
                          formatMoney(product.salePrice ?? 0, currencyCode),
                          style: TextStyle(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (product.trackInventory)
                          Text(
                            'المتوفر ${_numberText(available ?? 0)}',
                            style: TextStyle(
                              color: (available ?? 0) <= product.reorderPoint
                                  ? colors.error
                                  : colors.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        Text(
                          product.warrantyMonths == 0
                              ? 'بلا ضمان'
                              : 'ضمان ${product.warrantyMonths} شهر',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onEdit != null && onArchive != null)
                PopupMenuButton<_ProductAction>(
                  tooltip: 'إدارة المنتج',
                  onSelected: (action) => switch (action) {
                    _ProductAction.edit => onEdit!(),
                    _ProductAction.archive => onArchive!(),
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(
                      value: _ProductAction.edit,
                      child: ListTile(
                        leading: Icon(Icons.edit_outlined),
                        title: Text('تعديل المنتج'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    PopupMenuItem(
                      value: _ProductAction.archive,
                      child: ListTile(
                        leading: Icon(Icons.archive_outlined),
                        title: Text('أرشفة المنتج'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                )
              else
                Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 15,
                  color: colors.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _numberText(num value) =>
      value.toStringAsFixed(value % 1 == 0 ? 0 : 2);
}

enum _ProductAction { edit, archive }

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts({required this.hasQuery, required this.onAdd});

  final bool hasQuery;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 42,
              color: colors.onSurfaceVariant,
            ),
            const SizedBox(height: 10),
            Text(
              hasQuery ? 'لا يوجد منتج مطابق' : 'الكتالوج فارغ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              hasQuery
                  ? 'جرّب اسماً أو باركوداً آخر.'
                  : 'أضف المنتجات التي تبيعها لتسريع إصدار الضمان.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            if (!hasQuery && onAdd != null) ...[
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded),
                label: const Text('إضافة أول منتج'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
