import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../core/currency.dart';
import '../models/account.dart';
import '../models/product.dart';
import '../state/app_scope.dart';
import '../widgets/message_banner.dart';
import 'product_form_screen.dart';
import 'warranty_form_screen.dart';

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
                        'كتالوج المنتجات',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${controller.products.length} منتجاً جاهزاً للمسح وإصدار الضمان',
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
                          labelText: 'ابحث بالاسم أو الباركود أو رمز المخزون',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: _search.text.isEmpty
                              ? null
                              : IconButton(
                                  tooltip: 'مسح البحث',
                                  onPressed: () {
                                    _search.clear();
                                    setState(() {});
                                  },
                                  icon: const Icon(Icons.close_rounded),
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
    required this.onEdit,
    required this.onArchive,
  });

  final Product product;
  final VoidCallback? onEdit;
  final VoidCallback? onArchive;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currencyCode = AppScope.of(context).store!.currencyCode;
    return Card(
      child: InkWell(
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => WarrantyFormScreen(product: product),
          ),
        ),
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
                    Row(
                      children: [
                        Icon(
                          Icons.qr_code_2_rounded,
                          size: 15,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            product.barcode,
                            textDirection: TextDirection.ltr,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${product.warrantyMonths} شهراً',
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (product.salePrice != null) ...[
                          const SizedBox(width: 10),
                          Text(
                            formatMoney(product.salePrice!, currencyCode),
                            style: TextStyle(
                              fontSize: 12,
                              color: colors.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
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
