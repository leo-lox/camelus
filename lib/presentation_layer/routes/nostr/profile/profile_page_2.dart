import 'package:flutter/material.dart';

import '../../../../config/palette.dart';

class ProfilePage2 extends StatelessWidget {
  final String pubkey;
  const ProfilePage2({
    super.key,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxIsScrolled) {
            return <Widget>[
              SliverOverlapAbsorber(
                handle:
                    NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                sliver: SliverAppBar(
                  expandedHeight: 350,
                  pinned: true,
                  floating: true,
                  forceElevated: innerBoxIsScrolled,
                  backgroundColor: Palette.black, // Add a background color
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(),
                  ),
                  bottom: PreferredSize(
                    preferredSize: Size.fromHeight(48),
                    child: Container(
                      color: Palette
                          .darkGray, // Add a background color to the tab bar
                      child: TabBar(
                        tabs: [
                          Tab(text: 'Posts'),
                          Tab(text: 'Posts & Replies'),
                        ],
                        labelColor:
                            Colors.blue, // Set the color of the selected tab
                        unselectedLabelColor:
                            Colors.grey, // Set the color of unselected tabs
                        indicatorColor:
                            Colors.blue, // Set the color of the indicator
                      ),
                    ),
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              _buildScrollablePostsList(),
              _buildScrollablePostsAndRepliesList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Stack(
      children: [
        // Banner Image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 150, // Adjust the height as needed
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(
                    'https://static.vecteezy.com/system/resources/thumbnails/005/239/318/small/abstract-fluid-blue-wave-banner-background-illustration-vector.jpg'), // Replace with your banner image URL
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        // Profile Content
        Positioned(
          top:
              100, // Adjust this value to position the content below the banner
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: NetworkImage(
                          'https://static.vecteezy.com/system/resources/thumbnails/005/239/318/small/abstract-fluid-blue-wave-banner-background-illustration-vector.jpg'),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      child: Text('Follow'),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Text(
                  'John Doe',
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                Text('@johndoe', style: TextStyle(color: Colors.grey)),
                SizedBox(height: 8),
                Text('Flutter developer | Coffee enthusiast | Nature lover',
                    style: TextStyle(color: Colors.white)),
                SizedBox(height: 8),
                Row(
                  children: [
                    Text('1,234 Following',
                        style: TextStyle(color: Colors.white)),
                    SizedBox(width: 16),
                    Text('5,678 Followers',
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildScrollablePostsList() {
    return _ScrollablePostsList(
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
              'https://static.vecteezy.com/system/resources/thumbnails/005/239/318/small/abstract-fluid-blue-wave-banner-background-illustration-vector.jpg'),
        ),
        title: Text('John Doe'),
        subtitle: Text('This is a sample post ${index + 1}'),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }

  Widget _buildScrollablePostsAndRepliesList() {
    return _ScrollablePostsList(
      itemBuilder: (context, index) => ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(
              'https://static.vecteezy.com/system/resources/thumbnails/005/239/318/small/abstract-fluid-blue-wave-banner-background-illustration-vector.jpg'),
        ),
        title: Text('John Doe'),
        subtitle: Text('This is a sample post or reply ${index + 1}'),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}

class _ScrollablePostsList extends StatelessWidget {
  final Widget Function(BuildContext, int) itemBuilder;

  const _ScrollablePostsList({Key? key, required this.itemBuilder})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverOverlapInjector(
          handle: NestedScrollView.sliverOverlapAbsorberHandleFor(context),
        ),
        SliverPadding(
          padding: EdgeInsets.all(8.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (BuildContext context, int index) {
                return itemBuilder(context, index);
              },
              childCount: 30,
            ),
          ),
        ),
      ],
    );
  }
}
