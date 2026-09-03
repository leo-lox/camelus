import 'package:camelus/l10n/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Widget followButton({
  required bool isFollowing,
  required VoidCallback onPressed,
}) {
  if (isFollowing) {
    return Container(
      margin: const EdgeInsets.only(top: 0, right: 10),
      child: Builder(
        builder: (context) {
          return ElevatedButton(
            onPressed: () {
              onPressed();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: Theme.of(context).colorScheme.onSurface,
                  width: 1,
                ),
              ),
            ),
            child: Text(
              AppLocalizations.of(context)!.unfollow,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 16,
              ),
            ),
          );
        },
      ),
    );
  }
  return Container(
    margin: const EdgeInsets.only(top: 0, right: 10),
    child: Builder(
      builder: (context) {
        return ElevatedButton(
          onPressed: () {
            onPressed();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.onSurface,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: Theme.of(context).colorScheme.surface,
                width: 1,
              ),
            ),
          ),
          child: Text(
            AppLocalizations.of(context)!.follow,
            style: TextStyle(
              color: Theme.of(context).colorScheme.surface,
              fontSize: 16,
            ),
          ),
        );
      },
    ),
  );
}
