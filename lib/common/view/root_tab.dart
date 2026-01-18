import 'package:capstone_fe/common/const/colors.dart';
import 'package:capstone_fe/common/layout/default_layout.dart';
import 'package:capstone_fe/home/view/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class RootTab extends StatefulWidget {
  const RootTab({super.key});

  @override
  State<RootTab> createState() => _RootTabState();
}

class _RootTabState extends State<RootTab> with SingleTickerProviderStateMixin{
  late TabController controller;
  int index = 0;

  @override
  void initState() {
    super.initState();
    controller = TabController(length: 4, vsync: this);
    controller.addListener(tabListener);
  }
  @override
  void dispose() {
    controller.removeListener(tabListener);
    super.dispose();
  }

  void tabListener(){
    setState(() {
      index = controller.index;
    });
  }
  @override
  Widget build(BuildContext context) {
    return DefaultLayout(
      title: SvgPicture.asset('asset/img/try-on.svg'),
        actions: [
           IconButton(onPressed: (){}, icon: Icon(Icons.notifications_outlined)),
          IconButton(onPressed: (){}, icon: Icon(Icons.shopping_bag_outlined))
        ],
        bottomNavigationBar: BottomNavigationBar(
          backgroundColor: Colors.white,
          selectedItemColor: PRIMARYCOLOR,
            unselectedItemColor: BODY_COLOR,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            type: BottomNavigationBarType.fixed,
            onTap: (int index){
            controller.animateTo(index);
            },
            currentIndex: index,
            items: [
              BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: '홈'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.checkroom_outlined),
                  label: '피팅룸'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.door_sliding_outlined),
                  label: '옷장'
              ),
              BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  label: '피드'
              ),
            ]
        ),

        child: TabBarView(
          physics: NeverScrollableScrollPhysics(),
            controller: controller,
            children: [
              HomeScreen(),
              Center(child: Container(child: Text('피팅룸'))),
              Center(child: Container(child: Text('옷장'))),
              Center(child: Container(child: Text('피드'))),
        ]
        )
    );
  }
}
