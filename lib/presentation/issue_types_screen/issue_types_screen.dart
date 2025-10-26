import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/api/report_issue/issue_type_api.dart';
import '../../core/utils/icon_mapper.dart';
import '../../data/models/issue_type_model.dart';
import '../../l10n/app_localizations.dart';
import '../layouts/header_layout.dart';
import 'widgets/icon_picker_dialog.dart';
import 'widgets/issue_type_test_widget.dart';

/// Issue Types Management Screen
/// Only accessible by developers
class IssueTypesScreen extends StatefulWidget {
  const IssueTypesScreen({super.key});

  @override
  State<IssueTypesScreen> createState() => _IssueTypesScreenState();
}

class _IssueTypesScreenState extends State<IssueTypesScreen> {
  late final IssueTypeApi _issueTypeApi;
  List<IssueTypeModel> _issueTypes = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _issueTypeApi = IssueTypeApi();
    _loadIssueTypes();
  }

  Future<void> _loadIssueTypes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final types = await _issueTypeApi.getAllIssueTypes();
      if (mounted) {
        setState(() {
          _issueTypes = types;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: HeaderLayout(
        title: l10n.issueTypes_title,
        centerTitle: false,
        actions: [
          // 测试按钮（开发时使用）
          IconButton(
            icon: const Icon(Icons.science),
            tooltip: '测试 API',
            onPressed: () => _showTestWidget(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.issueTypes_create,
            onPressed: () => _showCreateDialog(context, l10n, theme),
          ),
        ],
      ),
      body: _buildBody(theme, l10n),
    );
  }

  Widget _buildBody(ThemeData theme, AppLocalizations l10n) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            SizedBox(height: 2.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: Text(
                '${l10n.issueTypes_errorPrefix}$_error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: _loadIssueTypes,
              child: Text(l10n.common_retry),
            ),
          ],
        ),
      );
    }

    if (_issueTypes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 48,
              color: theme.colorScheme.primary,
            ),
            SizedBox(height: 2.h),
            Text(l10n.issueTypes_noTypes, style: theme.textTheme.bodyLarge),
            SizedBox(height: 1.h),
            Text(
              l10n.issueTypes_createPrompt,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadIssueTypes,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _issueTypes.length,
        itemBuilder: (context, index) {
          final issueType = _issueTypes[index];
          return _buildIssueTypeCard(theme, l10n, issueType);
        },
      ),
    );
  }

  Widget _buildIssueTypeCard(
    ThemeData theme,
    AppLocalizations l10n,
    IssueTypeModel issueType,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isDark ? 2 : 1,
      color: theme.cardColor,
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          child: Icon(
            IconMapper.getIcon(issueType.iconUrl),
            color: theme.colorScheme.primary,
          ),
        ),
        title: Text(
          issueType.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        subtitle: issueType.description != null
            ? Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Text(
                  issueType.description!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
              )
            : null,
        trailing: PopupMenuButton<String>(
          icon: Icon(
            Icons.more_vert,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          onSelected: (value) {
            if (value == 'edit') {
              _showEditDialog(context, l10n, theme, issueType);
            } else if (value == 'delete') {
              _showDeleteDialog(context, l10n, theme, issueType);
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 20, color: theme.colorScheme.primary),
                  SizedBox(width: 2.w),
                  Text(l10n.common_edit),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 20, color: theme.colorScheme.error),
                  SizedBox(width: 2.w),
                  Text(l10n.common_delete),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    String? selectedIcon;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.issueTypes_create),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Selector
                InkWell(
                  onTap: () async {
                    final icon = await showDialog<String>(
                      context: context,
                      builder: (context) =>
                          IconPickerDialog(currentIcon: selectedIcon),
                    );
                    if (icon != null) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          IconMapper.getIcon(selectedIcon),
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Icon',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                selectedIcon ?? 'Select icon',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.issueTypes_name),
                  validator: (v) =>
                      v?.isEmpty ?? true ? l10n.issueTypes_nameRequired : null,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.issueTypes_description,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _createIssueType(
                    l10n,
                    nameController.text,
                    descController.text,
                    selectedIcon,
                  );
                }
              },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    IssueTypeModel issueType,
  ) {
    final nameController = TextEditingController(text: issueType.name);
    final descController = TextEditingController(text: issueType.description);
    String? selectedIcon = issueType.iconUrl;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.issueTypes_edit),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon Selector
                InkWell(
                  onTap: () async {
                    final icon = await showDialog<String>(
                      context: context,
                      builder: (context) =>
                          IconPickerDialog(currentIcon: selectedIcon),
                    );
                    if (icon != null) {
                      setState(() {
                        selectedIcon = icon;
                      });
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          IconMapper.getIcon(selectedIcon),
                          size: 32,
                          color: theme.colorScheme.primary,
                        ),
                        SizedBox(width: 3.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Icon',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                              ),
                              Text(
                                selectedIcon ?? 'Select icon',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: l10n.issueTypes_name),
                  validator: (v) =>
                      v?.isEmpty ?? true ? l10n.issueTypes_nameRequired : null,
                ),
                SizedBox(height: 2.h),
                TextFormField(
                  controller: descController,
                  decoration: InputDecoration(
                    labelText: l10n.issueTypes_description,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.common_cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  Navigator.pop(context);
                  await _updateIssueType(
                    l10n,
                    issueType.id,
                    nameController.text,
                    descController.text,
                    selectedIcon,
                  );
                }
              },
              child: Text(l10n.common_save),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
    IssueTypeModel issueType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.issueTypes_delete),
        content: Text(l10n.issueTypes_deleteConfirm(issueType.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.common_cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.error,
              foregroundColor: theme.colorScheme.onError,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await _deleteIssueType(l10n, issueType.id);
            },
            child: Text(l10n.common_delete),
          ),
        ],
      ),
    );
  }

  Future<void> _createIssueType(
    AppLocalizations l10n,
    String name,
    String description,
    String? iconUrl,
  ) async {
    try {
      await _issueTypeApi.createIssueType(
        name: name,
        description: description.isEmpty ? null : description,
        iconUrl: iconUrl,
      );
      await _loadIssueTypes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.issueTypes_created)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.issueTypes_errorPrefix}$e')),
        );
      }
    }
  }

  Future<void> _updateIssueType(
    AppLocalizations l10n,
    String id,
    String name,
    String description,
    String? iconUrl,
  ) async {
    try {
      await _issueTypeApi.updateIssueType(id, {
        'name': name,
        'description': description.isEmpty ? null : description,
        'icon_url': iconUrl,
      });
      await _loadIssueTypes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.issueTypes_updated)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.issueTypes_errorPrefix}$e')),
        );
      }
    }
  }

  Future<void> _deleteIssueType(AppLocalizations l10n, String id) async {
    try {
      await _issueTypeApi.deleteIssueType(id);
      await _loadIssueTypes();
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(l10n.issueTypes_deleted)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.issueTypes_errorPrefix}$e')),
        );
      }
    }
  }

  void _showTestWidget(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const IssueTypeTestWidget()),
    );
  }
}
