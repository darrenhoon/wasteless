import 'dart:convert';
import 'package:async/async.dart';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:LessApp/styles.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:LessApp/wasteless-data.dart';

class HistoryPage extends StatefulWidget{
  @override
  HistoryPageState createState() => new HistoryPageState();
}

class HistoryPageState extends  State<HistoryPage> {

  NumberFormat nf = NumberFormat("###.00", "en_US");

  String _selectedType = "General";
  String _selectedTrend = "Week";

  List<bool> _typeChosen = [true, false];
  List<String> _typeList = ["General", "Recyclables"];

  List<bool> _trendChosen = [true, false, false];
  List<String> _trendList = ["Week", "Month", "All Time"];
  List list = List();
  Map map = Map();
  WasteLessData data = new WasteLessData();

  final df = new DateFormat('dd-MM-yyyy hh:mm a');
  final df2 = new DateFormat(DateFormat.YEAR_MONTH_DAY, 'en_US');
  final df3 = DateFormat.yMMMd();
  final df4 = new DateFormat('d MMM yyyy');
  final df5 = new DateFormat('MMM');
  final dfFilter = DateFormat("yyyy-MM-dd");



  AsyncMemoizer _memoizer;
  @override
  void initState() {
    _memoizer = AsyncMemoizer();
  }

  _fetchData() async {
    return this._memoizer.runOnce(() async {

      int userID = 1234;

      String currentType;
      if (_typeChosen[0]) {
        currentType = "general";
      } else {
        currentType = "all";
      }

      String link = "https://yt7s7vt6bi.execute-api.ap-southeast-1.amazonaws.com/dev/waste/${userID.toString()}?aggregateBy=day&timeRangeStart=0&timeRangeEnd=1608364825&type=${currentType}";

      final response = await http.get(link, headers: {"x-api-key": WasteLessData.userKey});
      if (response.statusCode == 200) {
        map = json.decode(response.body) as Map;
        list = map["data"];
      } else {
        throw Exception('Failed to load data');
      }
    });
  }





  Widget _buildList() {

    var now = new DateTime.now();
    List newList;

    switch(_selectedTrend) {

      //month's worth of data
      case "Month": {
        newList = list.where((entry)=> DateTime.fromMillisecondsSinceEpoch(entry["time"] * 1000).month == DateTime.now().month )
            .toList();
      }
      break;

      //all time data
      case "All Time": {
        newList = list;
      }
      break;

      //week's worth of data
      default: {
        newList = list.where((entry) => DateTime.parse(dfFilter.format(DateTime.fromMillisecondsSinceEpoch(entry["time"] * 1000)).toString())
            .isAfter(DateTime(now.year, now.month, now.day).subtract(Duration(days: 6)))  )
            .toList();
      }

    }

    return Expanded(
        child: ListView.builder(
          itemCount: newList.length,
          reverse: true,
          itemBuilder: (BuildContext context, int index) {
            return ListTile(
              contentPadding: EdgeInsets.all(10.0),
              title: new Text(df4.format(DateTime.fromMillisecondsSinceEpoch(newList[index]["time"] * 1000)).toString()),
              //title: new Text(DateTime.now().month.toString()),
              subtitle: new Text(newList[index]["weight"].toString() + "kg"),
            );
            },
        )
    );
  }


  @override
  Widget build(BuildContext context) {

    _fetchData();

    return Scaffold(
        appBar: AppBar(
            title: Text("History",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          centerTitle: true,
          backgroundColor: Colors.white,
          elevation: 0,
        ),

        body: Container(
          alignment: Alignment.center,
          color: Colors.white,

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[

              Container(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                     DropdownButton<String>(
                       value: _selectedType,
                       items: _typeList.map((String value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: new Text(value),
                        );
                      }).toList(),
                      onChanged: (String newValue) {
                         setState(() {
                           for (int i = 0; i < _typeList.length; i++) {
                             String currType = _typeList[i];
                             if (newValue == currType) {
                               _typeChosen[i] = true;
                             } else {
                               _typeChosen[i] = false;
                             }
                           }
                           _selectedType = newValue;
                         });
                      },
                    ),

                    SizedBox(
                      height: 10,
                      width: 50,
                    ),

                    DropdownButton<String>(
                      value: _selectedTrend,
                      items: _trendList.map((String value) {
                        return new DropdownMenuItem<String>(
                          value: value,
                          child: new Text(value),
                        );
                      }).toList(),
                      onChanged: (String newValue) {
                        setState(() {
                          for (int i = 0; i < _trendList.length; i++) {
                            String currType = _trendList[i];
                            if (newValue == currType) {
                              _trendChosen[i] = true;
                            } else {
                              _trendChosen[i] = false;
                            }
                          }
                          _selectedTrend = newValue;
                        });
                      },
                    ),
                  ],
                ),
              ),

              _buildList(),



              /*
               * Previous Implementation using Firestore
              StreamBuilder(
                stream: Firestore
                    .instance
                    .collection("houses")
                    .document("House_A")
                    .collection("RawData")
                    .orderBy('timestamp', descending: true)
                    .snapshots(),


                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  } else return Expanded(
                    child: ListView.builder(
                        itemBuilder: (BuildContext context, int index) {
                          return Container(
                            color:   _typeChosen[0] ? ((index % 2 == 0) ? Colors.brown[100] : Colors.white10) : ((index % 2 == 0) ? Colors.lightGreenAccent : Colors.white10),
                            child: ListTile(
                              leading: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Padding(
                                    padding:  EdgeInsets.fromLTRB(10,0,0,0),
                                    child: Text((index+1).toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                ],
                              ),
                              title: Text(snapshot.data.documents[index]['timestamp2']),
                              subtitle: Text("Mass Thrown: " + snapshot.data.documents[index]['mass'].toString() + " kg"),
                            ),
                          );
                        }
                    )
                  );
                },
              )
              */


            ],
          )
        )
    );
  }
}