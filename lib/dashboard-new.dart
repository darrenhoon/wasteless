import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:csv_reader/csv_reader.dart';
import 'package:LessApp/styles.dart';
import 'dart:math';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:async/async.dart';
import 'package:LessApp/wasteless-data.dart';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:custom_switch/custom_switch.dart';
import 'package:lite_rolling_switch/lite_rolling_switch.dart';
import 'package:flutter_icons/flutter_icons.dart';
import 'package:toggle_switch/toggle_switch.dart';

class DashboardPage extends StatefulWidget{

  FirebaseUser user;
  DashboardPage(FirebaseUser user) {
    this.user = user;
  }


  @override
  DashboardPageState createState() => new DashboardPageState(this.user);

}

class DashboardPageState extends State<DashboardPage> {

  FirebaseUser user;
  DashboardPageState(this.user);

  NumberFormat nf = NumberFormat("##0.00", "en_US");

  double wasteThisWeek = 0.00;
  double areaAverageThisWeek = 0.00;

  double recyclablesThisWeek = 0.00;
  double areaAverageRecyclablesThisWeek = 0.00;

  List<bool> titleSelect = [true, false];
  List<String> title = ["Trash Dashboard", "Recycling Dashboard"];
  List<Color> colorPalette = [Colors.lightGreen[200], Colors.brown[100]];

  double sizeRelativeVisual = 1.0;

  final df3 = DateFormat.yMMMd();
  final dfFilter = DateFormat("yyyy-MM-dd");
  List list = List();
  Map map = Map();
  AsyncMemoizer _memoizer;
  bool isSelected = false;
  int isSelectedIndex = 0;

  List<List<dynamic>> dailyMessages = List();

  _fetchData(String party, String type) async {

    var now = new DateTime.now();
    var prevMonth = new DateTime(now.year, now.month - 1, now.day);
    var prevWeek = new DateTime(now.year, now.month, now.day - 6);

    String timeRangeStartValue = (prevWeek.millisecondsSinceEpoch * 1000).toString();
    String timeRangeEndValue = (now.millisecondsSinceEpoch * 1000).toString();


    String link;
    if (party == "self") {
      link = "https://yt7s7vt6bi.execute-api.ap-southeast-1.amazonaws.com/dev/waste/${user.uid.toString()}?aggregateBy=day&timeRangeStart=${timeRangeStartValue}&timeRangeEnd=${timeRangeEndValue}&type=${type}";
    } else {
      link = "https://yt7s7vt6bi.execute-api.ap-southeast-1.amazonaws.com/dev/waste?aggregateBy=day&timeRangeStart=0&timeRangeEnd=1608364825&type=${type}";
    }

    final response = await http.get(link, headers: {"x-api-key": WasteLessData.userKey});
    if (response.statusCode == 200) {
      map = json.decode(response.body) as Map;
      list = map["data"];
    } else {
      throw Exception('Failed to load data');
    }
  }

  Widget _buildStats(String party, String type) {

    var now = new DateTime.now();
    List newList = list.where((entry) => DateTime.parse(dfFilter.format(DateTime.fromMillisecondsSinceEpoch(entry["time"] * 1000)).toString())
        .isAfter(DateTime(now.year, now.month, now.day).subtract(Duration(days: 6)))  )
        .toList();

    double averageValue = newList.fold(0, (current, entry) => current + entry["weight"]) / 7.0;

    if (type == "general") {
      if (party == "self") {
        wasteThisWeek = averageValue;
      } else {
        areaAverageThisWeek = averageValue;
      }
    } else {
      if (party == "self") {
        recyclablesThisWeek = averageValue;
      } else {
        areaAverageRecyclablesThisWeek = averageValue;
      }
    }

    setState(() {
      if (type == "general") {
        if (party == "self") {
          wasteThisWeek = averageValue;
        } else {
          areaAverageThisWeek = averageValue;
        }
      } else {
        if (party == "self") {
          recyclablesThisWeek = averageValue;
        } else {
          areaAverageRecyclablesThisWeek = averageValue;
        }
      }
    });

    return FutureBuilder(
        future: _fetchData("self", type),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Text(nf.format(averageValue) + "kg",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 50,
                fontWeight: FontWeight.bold,
              ),
            );
          } else {
            return CircularProgressIndicator();
          }
        }
    );
  }

  static String stateSelector(double a, double b) {
    if (b == 0) {
      return "rubbishEmpty";
    }

    double percFill = (a/b)*100;
    if (percFill < 50.0) {
      return "rubbishEmpty";
    } else if (50.0 <= percFill && percFill < 80.0) {
      return "rubbishFilled";
    } else {
      return "rubbishOverflow";
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    String name = user.uid;

    return Scaffold(

      body: SafeArea(
            child: SingleChildScrollView(
              child: Center(
                child: Column(
                  children: <Widget>[
                    Column(
                        children: <Widget>[
                          Container(
                            padding: EdgeInsets.fromLTRB(15, 15, 15,0),
                            width: size.width,
                            child: Text("Welcome,",
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                fontSize: 25,
                                color: Colors.black45
                              ),
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.fromLTRB(15, 5, 15,15),
                            width: size.width,
                            child: Text(name,
                              textAlign: TextAlign.left,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 65
                              ),
                            ),
                          ),

                          Container(
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                            width: size.width*0.95,
                            height: 200,
                            decoration: BoxDecoration(
                                gradient: new LinearGradient(
                                    colors: [Colors.brown,Colors.brown[200]],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.brown[100],
                                    blurRadius: 10,
                                    offset: Offset(10.0,10.0),

                                  ),
                                ]
                            ),
                            child: Row(
                              children: <Widget>[

                                trashBin(stateSelector(this.wasteThisWeek, this.areaAverageThisWeek)),
                                Spacer(),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[

                                    Text("This week you threw",
                                      style: TextStyle(
                                        fontSize: MediaQuery.of(context).size.height / 50,
                                      ),
                                    ),

                                    SizedBox(
                                      height: MediaQuery.of(context).size.height / 50,
                                    ),

                                    _buildStats("self", "general"),


                                  ],
                                )

                              ],

                            ),
                          ),

                          SizedBox(
                              height: size.height * 0.02,
                          ),

                          Container(
                            padding: EdgeInsets.fromLTRB(15, 0, 15, 0),
                            width: size.width*0.95,
                            height: 200,
                            decoration: BoxDecoration(
                                gradient: new LinearGradient(
                                    colors: [Colors.green[700],Colors.green[200]],
                                    begin: Alignment.centerRight,
                                    end: Alignment.centerLeft
                                ),
                                borderRadius: BorderRadius.all(Radius.circular(20)),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green[100],
                                    blurRadius: 10,
                                    offset: Offset(10.0,10.0),

                                  ),
                                ]
                            ),
                            child: Row(

                              children: <Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[

                                    Text("This week you recycled",
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context).size.height / 50,
                                        )),
                                    SizedBox(
                                      height: MediaQuery.of(context).size.height / 50,
                                    ),
                                    _buildStats("self", "all"),


                                  ],
                                ),
                                Spacer(),
                                Image.asset('assets/recyclingIsland.png',
                                  height: MediaQuery.of(context).size.height / 6,
                                  width: MediaQuery.of(context).size.height / 6,
                                ),

                              ],

                            ),
                          ),

                        ],
                      ),
                  ],
                ),
              ),
            ),

      ),
      );
  }

  Widget trashBin(String selectedState) {
    if (selectedState == "rubbishEmpty") {
      return Image.asset('assets/rubbishEmptyIsland.png',
      height: MediaQuery.of(context).size.height / 6,
      width: MediaQuery.of(context).size.height / 6,
      );
    } else if (selectedState == 'rubbishFilled') {
      return Image.asset('assets/rubbishFilledIsland.png',
        height: MediaQuery.of(context).size.height / 6,
        width: MediaQuery.of(context).size.height / 6,
      );
    } else if (selectedState == 'rubbishOverflow') {
      return Image.asset('assets/rubbishOverflowIsland.png',
        height: MediaQuery.of(context).size.height / 6,
        width: MediaQuery.of(context).size.height / 6,
      );
    }
  }

}