import 'package:material_ui/material_ui.dart';

class WalletSheetSendReceive extends StatelessWidget {
  const WalletSheetSendReceive(
      {super.key,
      required this.isHideBottomNavBar,
      required this.pageChangeStream});

  final Function(bool) isHideBottomNavBar;
  final Stream<int> pageChangeStream;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: EdgeInsets.only(top: 25), // const EdgeInsets.all(15),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Row(children: [
              SizedBox(
                height: 85,
                child: Column(
                  children: [
                    ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(7),
                          elevation: 0,
                        ),
                        child:
                            const Icon(Icons.file_upload_outlined, size: 40)),
                    const SizedBox(height: 5),
                    const Text("send")
                  ],
                ),
              ),
            ]),
            Row(children: [
              SizedBox(
                height: 85,
                child: Column(
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          print("unimplemented");
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(7),
                          elevation: 0,
                        ),
                        child:
                            const Icon(Icons.file_download_outlined, size: 40)),
                    const SizedBox(height: 5),
                    const Text("receive")
                  ],
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
