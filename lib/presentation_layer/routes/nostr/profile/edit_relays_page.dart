import 'package:camelus/domain_layer/entities/relay.dart';
import 'package:camelus/l10n/app_localizations.dart';
import 'package:camelus/presentation_layer/components/edit_relays_view.dart';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class EditRelaysPage extends ConsumerStatefulWidget {
  const EditRelaysPage({super.key});

  @override
  ConsumerState<EditRelaysPage> createState() => _EditRelaysPageState();
}

class _EditRelaysPageState extends ConsumerState<EditRelaysPage> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future onSave(List<Relay> changedRelays) async {
    throw UnimplementedError("save in nip65");
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(title: Text(AppLocalizations.of(context)!.editRelays)),
        // show loading indicator when reconnecting
        body: EditRelaysView(onSave: onSave),
      ),
    );
  }
}
