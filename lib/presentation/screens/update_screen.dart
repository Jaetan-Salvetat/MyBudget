import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:mybudget/core/controllers/update_controller.dart';
import 'package:mybudget/domain/entities/release_info.dart';
import 'package:mybudget/core/routes/app_routes.dart';

class UpdateScreen extends StatelessWidget {
  const UpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<UpdateController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nouvelle mise à jour'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        final release = controller.latestRelease.value;
        if (release == null) {
          return const Center(child: Text('Aucune mise à jour disponible'));
        }
        
        return _buildUpdateContent(context, controller, release);
      }),
    );
  }
  
  Widget _buildUpdateContent(
    BuildContext context, 
    UpdateController controller,
    ReleaseInfo release,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            release.title,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Version ${release.version}',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Publiée le ${_formatDate(release.publishedAt)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            'Notes de version',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: MarkdownBody(
              data: release.notes,
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)),
            ),
          ),
          const SizedBox(height: 24),
          Obx(() => _buildActionButton(context, controller)),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
  
  Widget _buildActionButton(BuildContext context, UpdateController controller) {
    switch (controller.status.value) {
      case UpdateStatus.available:
        return _buildDownloadButton(context, controller);
        
      case UpdateStatus.downloading:
        return _buildProgressIndicator(context, controller);
        
      case UpdateStatus.readyToInstall:
        return _buildInstallButton(context, controller);
        
      case UpdateStatus.installing:
        return const Center(
          child: CircularProgressIndicator(),
        );
        
      case UpdateStatus.error:
        return _buildRetryButton(context, controller);
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildDownloadButton(BuildContext context, UpdateController controller) {
    final releaseSize = _formatFileSize(controller.latestRelease.value?.assetSize ?? 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Taille du téléchargement: $releaseSize', 
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => controller.downloadUpdate(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Télécharger la mise à jour'),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () => Get.offAllNamed(AppRoutes.dashboard),
            child: const Text('Ignorer cette mise à jour'),
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator(BuildContext context, UpdateController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Obx(() => Text(
          'Téléchargement: ${(controller.downloadProgress.value * 100).toInt()}%',
          style: Theme.of(context).textTheme.bodyMedium,
        )),
        const SizedBox(height: 8),
        Obx(() => LinearProgressIndicator(
          value: controller.downloadProgress.value,
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).colorScheme.primary,
          ),
        )),
      ],
    );
  }
  
  Widget _buildInstallButton(BuildContext context, UpdateController controller) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => controller.installUpdate(),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
        ),
        child: const Text('Installer maintenant'),
      ),
    );
  }
  
  Widget _buildRetryButton(BuildContext context, UpdateController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Une erreur est survenue lors de la mise à jour',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => controller.downloadUpdate(),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            child: const Text('Réessayer'),
          ),
        ),
      ],
    );
  }
  
  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    
    return '$day/$month/$year';
  }
  
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
