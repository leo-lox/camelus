import 'dart:developer';

import 'package:flutter/material.dart';

class WalletFriendsStrip extends StatelessWidget {
  const WalletFriendsStrip({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width,
      height: 130,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(15, 4, 15, 0),
            child: Text(
              "friends",
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 24,
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(15, 2, 15, 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  onTap: () => {print("unimplemented")},
                  child: Column(
                    children: const [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://images.pexels.com/photos/220453/pexels-photo-220453.jpeg",
                        ),
                        radius: 30,
                      ),
                      Text("user1", style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(10)),
                  onTap: () => {print("nimplemented;")},
                  child: Column(
                    children: const [
                      CircleAvatar(
                        backgroundImage: NetworkImage(
                          "https://www.venmond.com/demo/vendroid/img/avatar/big.jpg",
                        ),
                        radius: 30,
                      ),
                      Text("user2", style: TextStyle(fontSize: 15)),
                    ],
                  ),
                ),
                const SizedBox(width: 15),
                InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(50)),
                  onTap: () => {log("todo")},
                  child: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    radius: 30,
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
