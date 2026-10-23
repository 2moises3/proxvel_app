import 'dart:ui';
import '../../theme/app_layout.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ProxvelGlassPickerSheet extends StatefulWidget {
  final String title;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String> onSelected;

  const ProxvelGlassPickerSheet({
    super.key,
    required this.title,
    required this.items,
    this.selectedItem,
    required this.onSelected,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required List<String> items,
    String? selectedItem,
    required ValueChanged<String> onSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProxvelGlassPickerSheet(
        title: title,
        items: items,
        selectedItem: selectedItem,
        onSelected: onSelected,
      ),
    );
  }

  @override
  State<ProxvelGlassPickerSheet> createState() => _ProxvelGlassPickerSheetState();
}

class _ProxvelGlassPickerSheetState extends State<ProxvelGlassPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredItems = [];

  @override
  void initState() {
    super.initState();
    _filteredItems = widget.items;
  }

  void _filterItems(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredItems = widget.items;
      } else {
        _filteredItems = widget.items
            .where((item) => item.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF10141C).withValues(alpha: 0.75),
                  const Color(0xFF080A0F).withValues(alpha: 0.85),
                ],
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.sheet)),
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 1),
              ),
            ),
            child: SafeArea(
              bottom: true,
              child: Padding(
                padding: EdgeInsets.only(bottom: bottomInset),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: AppSpace.content),
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: AppSpace.section),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.poppins(
                          color: Colors.white.withValues(alpha: 0.95),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpace.card),
                    if (widget.items.length > 8)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                        child: TextField(
                          controller: _searchController,
                          onChanged: _filterItems,
                          style: GoogleFonts.poppins(color: Colors.white, fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: GoogleFonts.poppins(color: Colors.white.withValues(alpha: 0.3), fontSize: 14),
                            prefixIcon: Icon(Icons.search_rounded, color: Colors.white.withValues(alpha: 0.4), size: 18),
                            filled: true,
                            fillColor: Colors.white.withValues(alpha: 0.06),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08), width: 0.5),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.15), width: 1),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    if (widget.items.length > 8) const SizedBox(height: AppSpace.content),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredItems.length,
                        separatorBuilder: (context, index) => Divider(
                          color: Colors.white.withValues(alpha: 0.03),
                          height: 1,
                          indent: 24,
                          endIndent: 24,
                        ),
                        itemBuilder: (context, index) {
                          final item = _filteredItems[index];
                          final isSelected = item == widget.selectedItem;
                          return InkWell(
                            onTap: () {
                              widget.onSelected(item);
                              Navigator.pop(context);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                              color: isSelected ? Colors.white.withValues(alpha: 0.03) : Colors.transparent,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item,
                                      style: GoogleFonts.poppins(
                                        color: isSelected ? const Color(0xFFFDBA00) : Colors.white.withValues(alpha: 0.8),
                                        fontSize: 15,
                                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_rounded,
                                      color: Color(0xFFFDBA00),
                                      size: 20,
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
