import 'package:flutter/material.dart';
import '../core/constants.dart';

class ModelSelectorWidget extends StatelessWidget {
  final String selectedProvider;
  final String selectedModel;
  final ValueChanged<String> onProviderChanged;
  final ValueChanged<String> onModelChanged;

  const ModelSelectorWidget({
    super.key,
    required this.selectedProvider,
    required this.selectedModel,
    required this.onProviderChanged,
    required this.onModelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final models = ProviderModels.models[selectedProvider] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('AI Provider', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: selectedProvider,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.smart_toy_outlined),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: ProviderModels.providerNames.entries
              .map((e) => DropdownMenuItem(
                    value: e.key,
                    child: Text(e.value),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onProviderChanged(value);
          },
        ),
        const SizedBox(height: 16),
        Text('Model', style: theme.textTheme.labelLarge),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: models.contains(selectedModel) ? selectedModel : models.first,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.model_training),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: models
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Text(m),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) onModelChanged(value);
          },
        ),
      ],
    );
  }
}
