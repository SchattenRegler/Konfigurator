part of 'sector_widget.dart';

extension _LouvreTab on _SectorWidgetState {
  Widget _buildLouvreTrackingTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: sector.louvreSpacing.toStringAsFixed(1),
                  decoration: const InputDecoration(
                    labelText: 'Lamellenabstand (mm)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null && val > 0) {
                      setState(() {
                        sector.louvreSpacing = val;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: sector.louvreDepth.toStringAsFixed(1),
                  decoration: const InputDecoration(
                    labelText: 'Lamellentiefe (mm)',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (v) {
                    final val = double.tryParse(v);
                    if (val != null && val > 0) {
                      setState(() {
                        sector.louvreDepth = val;
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(width: 160),
          ElevatedButton(onPressed: () {}, child: const Text('Empty')),
        ],
      ),
    );
  }
}
