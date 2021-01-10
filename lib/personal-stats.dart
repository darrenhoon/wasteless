import 'dart:ui';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:charts_flutter/flutter.dart' as charts;
import 'package:WasteLess/massEntry.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:WasteLess/styles.dart';
import 'dart:convert';
import 'package:async/async.dart';
import 'package:http/http.dart' as http;
import 'package:WasteLess/wasteless-data.dart';
import 'package:date_utils/date_utils.dart';

class PersonalStatsPage extends StatefulWidget{
  final bool userSelectedChoice ;
  final FirebaseUser user;
  PersonalStatsPage(this.user,this.userSelectedChoice);

  @override
  PersonalStatsPageState createState() => new PersonalStatsPageState(this.user,this.userSelectedChoice);
}

class PersonalStatsPageState extends State<PersonalStatsPage>{
  FirebaseUser user;
  bool userSelectedChoice;
  PersonalStatsPageState(this.user,this.userSelectedChoice);

  final now = DateTime.now();
  String selectedTime = "week";
  String selectedType = "general";
  List<bool> isSelectedTrend = [true, false, false];
  List<bool> isSelectedType = [false, true, false];

  List<bool> isSelectedTypeAll = [true, false];
  List<String> title = ["Personal Trash Stats", "Personal Recycling Stats"];

  List<Color> colorPalette = [Colors.lightGreen[200], Colors.brown[100]];
  List<charts.Series<MassEntry, String>> _seriesBarData;
  List<charts.Series<formattedWeekEntry, String>> _weekSeriesBarData;
  List<charts.Series<MassEntry, DateTime>> _timeChartData;
  List<MassEntry> myData, massEntryDay;
  static int pageCounter = 15001;

  double personalWeekAverageGeneral = 0.00;
  double areaWeekAverageGeneral = 0.00;

  double personalWeekAverageAll = 0.00;
  double areaWeekAverageAll = 0.00;
  double personalWeekAveragePlastic = 0.00;
  double areaWeekAveragePlastic = 0.00;
  double personalWeekAveragePaper = 0.00;
  double areaWeekAveragePaper = 0.00;


  NumberFormat nf = NumberFormat("#00.00", "en_US");
  final df3 = DateFormat.yMMMd();
  final dfFilter = DateFormat("yyyy-MM-dd");
  int userID = 1234;

  List list = List();
  List areaList = List();

  Map map = Map();
  bool isSelected = false;
  // int isSelectedIndex = 0;


  @override
  void initState() {
    isSelectedTypeAll[0] = userSelectedChoice;
  }

  _fetchDataPersonal(String type) async {

    String typeNum = type == "general" ? "1" : "4";

    int numOfDays ;
    switch (DateFormat('E').format(DateTime.now())) {

      case 'Mon' : {
        numOfDays = 0;
        break;
      }
      case 'Tue' : {
        numOfDays = 1;
        break;
      }
      case 'Wed' : {
        numOfDays = 2;
        break;
      }
      case 'Thu' : {
        numOfDays = 3;
        break;
      }
      case 'Fri' : {
        numOfDays = 4;
        break;
      }
      case 'Sat' : {
        numOfDays = 5;
        break;
      }
      case 'Sun' : {
        numOfDays = 6;
        break;
      }
    }

    var now = new DateTime.now();
    var prevMonth = new DateTime(now.year, now.month, 1); //fix to be first day of every month
    var prevWeek = new DateTime(now.year, now.month, now.day - numOfDays);

    String timeRangeStartValue;
    String timeRangeEndValue = (now.millisecondsSinceEpoch ~/ 1000).toString();

    if (selectedTime == "allTime") {
      //TODO: AFTER TESTING, CHANGE THIS VALUE. should at least be 1609926000
      timeRangeStartValue = "0"; //6th Jan, 2021, 5.53pm
    } else if (selectedTime == "month") {
      timeRangeStartValue = (prevMonth.millisecondsSinceEpoch ~/ 1000).toString();
    } else { //week
      timeRangeStartValue = (prevWeek.millisecondsSinceEpoch ~/ 1000).toString();
    }

    String link = "https://yt7s7vt6bi.execute-api.ap-southeast-1.amazonaws.com/dev/waste/${user.uid.toString()}?aggregateBy=day&timeRangeStart=${timeRangeStartValue}&timeRangeEnd=${timeRangeEndValue}&type=${typeNum}";

    final response = await http.get(link, headers: {"x-api-key": WasteLessData.userKey});

    if (response.statusCode == 200) {
      map = json.decode(response.body) as Map;
      list = map["data"];

      /*
      print("VVVVV");
      print("FETCHDATA");
      print("selected type: " + selectedType);
      print("selected time: " + selectedTime);
      print("Current TimeRangeEndValue: " + timeRangeEndValue);
      print("Now value: " + (now.millisecondsSinceEpoch ~/ 1000).toString());
      print("Current TimeRangeStart value: " + timeRangeStartValue);
      print("preMonth value: " + (prevMonth.millisecondsSinceEpoch ~/ 1000).toString());
      print("preWeek value: " + (prevWeek.millisecondsSinceEpoch ~/ 1000).toString());
      print("CurrentList: " + list.toString());
      print("link :" + link);
      print("^^^^^");
      */


    } else {
      throw Exception('Failed to load data');
    }

  }

  _fetchDataArea(String type) async {

    String typeNum = type == "general" ? "1" : "2";

    int numOfDays ;
    switch (DateFormat('E').format(DateTime.now())) {

      case 'Mon' : {
        numOfDays = 0;
        break;
      }
      case 'Tue' : {
        numOfDays = 1;
        break;
      }
      case 'Wed' : {
        numOfDays = 2;
        break;
      }
      case 'Thu' : {
        numOfDays = 3;
        break;
      }
      case 'Fri' : {
        numOfDays = 4;
        break;
      }
      case 'Sat' : {
        numOfDays = 5;
        break;
      }
      case 'Sun' : {
        numOfDays = 6;
        break;
      }
    }

    var now = new DateTime.now();
    var prevMonth = new DateTime(now.year, now.month, 1); //fix to be first day of every month
    var prevWeek = new DateTime(now.year, now.month, now.day - numOfDays);

    String timeRangeStartValue;
    String timeRangeEndValue = (now.millisecondsSinceEpoch ~/ 1000).toString();

    if (selectedTime == "allTime") {
      //TODO: AFTER TESTING, CHANGE THIS VALUE. should at least be 1609926000
      timeRangeStartValue = "0"; //6th Jan, 2021, 5.53pm
    } else if (selectedTime == "month") {
      timeRangeStartValue = (prevMonth.millisecondsSinceEpoch ~/ 1000).toString();
    } else { //week
      timeRangeStartValue = (prevWeek.millisecondsSinceEpoch ~/ 1000).toString();
    }

    String link = "https://yt7s7vt6bi.execute-api.ap-southeast-1.amazonaws.com/dev/waste?aggregateBy=day&timeRangeStart=${timeRangeStartValue}&timeRangeEnd=${timeRangeEndValue}&type=${typeNum}";

    final response = await http.get(link, headers: {"x-api-key": WasteLessData.userKey});

    if (response.statusCode == 200) {
      map = json.decode(response.body) as Map;
      areaList = map["data"];

      /*
      print("VVVVV");
      print("FETCHDATA");
      print("selected type: " + selectedType);
      print("selected time: " + selectedTime);
      print("Current TimeRangeEndValue: " + timeRangeEndValue);
      print("Now value: " + (now.millisecondsSinceEpoch ~/ 1000).toString());
      print("Current TimeRangeStart value: " + timeRangeStartValue);
      print("preMonth value: " + (prevMonth.millisecondsSinceEpoch ~/ 1000).toString());
      print("preWeek value: " + (prevWeek.millisecondsSinceEpoch ~/ 1000).toString());
      print("CurrentList: " + list.toString());
      print("link :" + link);
      print("^^^^^");
      */


    } else {
      throw Exception('Failed to load data');
    }
  }

  _generateData(myData) {
    _seriesBarData = List<charts.Series<MassEntry, String>>();
    _seriesBarData.add(
      charts.Series(
        domainFn: (MassEntry massEntry, _) => massEntry.timestamp,
        measureFn: (MassEntry massEntry, _) => massEntry.mass,
        seriesColor: charts.ColorUtil.fromDartColor(Colors.green),
        id: 'Mass',
        data: myData,

      ),
    );
  }

  _generateDailyData(myData) {
    _seriesBarData = List<charts.Series<MassEntry, String>>();
    _seriesBarData.add(
      charts.Series(
        domainFn: (MassEntry massEntry, _) => DateFormat.Hm().format(massEntry.dateTimeValue),
        measureFn: (MassEntry massEntry, _) => massEntry.mass,
        seriesColor: charts.ColorUtil.fromDartColor(Colors.green),
        id: 'Mass',
        data: myData,

      ),
    );
  }

  _generateComDayData(myData) {
    _seriesBarData = List<charts.Series<MassEntry, String>>();
    _seriesBarData.add(
      charts.Series(
        domainFn: (MassEntry massEntry, _) => massEntry.day,
        measureFn: (MassEntry massEntry, _) => massEntry.mass,
        seriesColor: charts.ColorUtil.fromDartColor(isSelectedTypeAll[0] ? Colors.brown : Colors.green),
        id: 'Mass',
        data: myData,

      ),
    );
  }

  _generateWeeklyData(myData) {
    _weekSeriesBarData = List<charts.Series<formattedWeekEntry, String>>();
    _weekSeriesBarData.add(
      charts.Series(
        domainFn: (formattedWeekEntry e, _) => e.day,
        measureFn: (formattedWeekEntry e, _) => e.mass,
        seriesColor: charts.ColorUtil.fromDartColor(isSelectedTypeAll[0] ? Colors.brown : Colors.green),
        id: 'Mass',
        data: myData,

      ),
    );
  }
  _generateTimeChartData(myData) {
    _timeChartData = List<charts.Series<MassEntry, DateTime>>();

    _timeChartData.add(
      charts.Series(
        domainFn: (MassEntry massEntry, _) => massEntry.dateTimeValue,
        measureFn: (MassEntry massEntry, _) => massEntry.mass,
        colorFn: (_, __) => isSelectedTypeAll[0] ? charts.MaterialPalette.deepOrange.shadeDefault: charts.MaterialPalette.green.shadeDefault,
        areaColorFn: (MassEntry massEntry, _) => isSelectedTypeAll[0] ? charts.MaterialPalette.deepOrange.shadeDefault.lighter : charts.MaterialPalette.green.shadeDefault.lighter,
        // seriesColor: charts.ColorUtil.fromDartColor(Colors.green),
        id: 'Mass',
        data: myData,
      ),
    );
  }

  static Text getPersonalWeekTotal(String house) {

    StreamBuilder<QuerySnapshot>(
        stream: Firestore.instance
            .collection('houses')
            .document(house)
            .collection("RawData")
            .snapshots(),

        builder: (context, snapshot) {

          if (!snapshot.hasData) {
            return Styles.formatNumber(0.00);
          }
          else {
            //print(snapshot.toString());
            List<MassEntry> weekData = snapshot.data.documents
                .map((documentSnapshot) =>
                MassEntry.fromMap(documentSnapshot.data))
                .toList()
                .where((i) =>
                DateTime.parse(i.timestamp).isAfter(DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day)
                    .subtract(Duration(days: 6))))
                .toList();
            double weeklyMass = weekData.fold(0, (previousValue, element) => previousValue + element.mass);
            //debugPrint(weeklyMass.toString());
            return Styles.formatNumber(38.2);
          }
        }
    );
  }

  Widget recyclingBar() {

    bool paperVisible = PersonalStatsPageState.pageCounter % 3 == 0;
    bool allVisible = PersonalStatsPageState.pageCounter % 3 == 1;
    bool plasticVisible = PersonalStatsPageState.pageCounter % 3 == 2;

    return Container(
        decoration: BoxDecoration(
          color: isSelectedTypeAll[0] ? colorPalette[1]: colorPalette[0],
          //Colors.lightGreen[200],
          borderRadius: BorderRadius.circular(5),
        ),
        height: MediaQuery.of(context).size.height/20,
        width: MediaQuery.of(context).size.width/1.05,
        padding: EdgeInsets.all(7),
        child: Center(
          child: Row(
            children: <Widget>[
              FlatButton(
                child: Icon(Icons.arrow_back),
                onPressed: () {
                  //PersonalStatsPageState.pageCounter--;
                  setState(() {
                    PersonalStatsPageState.pageCounter--;

                    if (isSelectedTypeAll[0]) {
                      selectedType = "general";
                    } else {
                      if (PersonalStatsPageState.pageCounter % 3 == 0) {
                        selectedType = "plastic";
                      } else
                      if (PersonalStatsPageState.pageCounter % 3 == 1) {
                        selectedType = "all";
                      } else {
                        selectedType = "plastic";
                      }
                    }
                  });


                },
              ),

              allVisible ? Text("                All                ",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width/20,
                  fontWeight: FontWeight.bold,
                ),
              ) : new Container(),

              paperVisible ? Text("             Paper              ",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width/20,
                  fontWeight: FontWeight.bold,
                ),
              ) : new Container(),

              plasticVisible ? Text("             Plastic            ",
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width/20,
                  fontWeight: FontWeight.bold,
                ),
              ) : new Container(),

              FlatButton(
                child: Icon(Icons.arrow_forward),
                onPressed: () {
                  //PersonalStatsPageState.pageCounter++;

                  setState(() {
                    PersonalStatsPageState.pageCounter++;
                  });

                },
              ),

            ],
          ),
        )
    );
  }

  Widget throwingText() {
    String text = isSelectedTypeAll[0] ? "Today you threw away" : "Today you recycled";
    return Text(text,
      style: TextStyle(
        fontSize: MediaQuery.of(context).size.width/18,
      ),
    );
  }


  @override
  Widget build(BuildContext context) {

    String currentTitle;
    if (isSelectedTypeAll[0]) {
      currentTitle = title[0];
    } else {
      currentTitle = title[1];
    }

    return Scaffold(
      //appBar: Styles.MainStatsPageHeader(title[0], FontWeight.bold, Colors.black),
      appBar: AppBar(
        leading: IconButton(
            icon: Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context, true);
            }),
        centerTitle: true,
        title: Text(currentTitle,
              style: TextStyle(
                color: Colors.white,
              ),
            ),
        backgroundColor: Colors.green[900],
        elevation: 0,

      ),
      body: Container(
        alignment: Alignment.center,
        color: Colors.white,

        child: Column(
          children: <Widget>[

            isSelectedTypeAll[0] ? new Container() : SizedBox(
              height: MediaQuery.of(context).size.height/50,
            ),

            //type selection
            isSelectedTypeAll[0] ? new Container() : recyclingBar(),

            SizedBox(
              height: MediaQuery.of(context).size.height/50,
            ),

            //trend selection
            Container(
              decoration: BoxDecoration(
                color: isSelectedTypeAll[0] ? colorPalette[1]: colorPalette[0],
                borderRadius: BorderRadius.circular(5),
              ),
              height: MediaQuery.of(context).size.height/20,
              width: MediaQuery.of(context).size.width/1.05,
              padding: EdgeInsets.all(7),
              child: Center(
                child: ToggleButtons(
                  renderBorder: false,

                  children: <Widget>[
                    Text("  Week  ",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width/20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("  Month  ",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width/20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("  All Time  ",
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width/20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                  onPressed: (int index) {


                    setState(() {
                      switch(index){
                        case 0: {selectedTime = "week";}
                        break;
                        case 1: {selectedTime = "month";}
                        break;
                        case 2: {selectedTime = "allTime";}
                        break;
                      }

                      for (int buttonIndex = 0; buttonIndex < isSelectedTrend.length; buttonIndex++) {
                        if (buttonIndex == index) {
                          isSelectedTrend[buttonIndex] = true;
                        } else {
                          isSelectedTrend[buttonIndex] = false;
                        }
                      }
                    });

                  },
                  isSelected: isSelectedTrend,
                ),
              )
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height/50,
            ),

            Container(
              decoration: BoxDecoration(
                color:  isSelectedTypeAll[0] ? colorPalette[1]: colorPalette[0],
                borderRadius: BorderRadius.circular(5),
              ),
              height: MediaQuery.of(context).size.height/8,
              width: MediaQuery.of(context).size.width/1.05,
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[

                  throwingText(),

                  SizedBox(
                      height: MediaQuery.of(context).size.height/100,
                  ),

                  FutureBuilder(
                      future: _fetchDataPersonal(selectedType),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return _buildStatsDailyInfo("self");
                        } else {
                          return CircularProgressIndicator();
                        }
                      }
                  ),
                ],
              ),
            ),

            SizedBox(
              height: MediaQuery.of(context).size.height/50,
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                (isSelectedTrend[0] || isSelectedTrend[1]) ? Container(
                  decoration: BoxDecoration(
                    color: isSelectedTypeAll[0] ? colorPalette[1]: colorPalette[0],
                    //Colors.lightGreen[200],
                    borderRadius: BorderRadius.circular(5),
                  ),
                  height: MediaQuery.of(context).size.height/15,
                  width: MediaQuery.of(context).size.width/1.05,
                  padding: EdgeInsets.all(7),
                  child:  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[

                      Container(
                        child: Text("Personal\nWeek Average: ",
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width/30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      FutureBuilder(
                          future: _fetchDataPersonal(selectedType),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return _buildStatsInfo("self", selectedTime, Colors.purple);
                            }
                            else {
                              return CircularProgressIndicator();
                            }
                          }
                      ),

                      Container(
                        child: Text("Tembusu\nWeek Average: ",
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width/30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      FutureBuilder(
                          future: _fetchDataArea(selectedType),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done) {
                              return _buildStatsInfo("Tembusu", selectedTime, Colors.teal.shade900);
                            }
                            else {
                              return CircularProgressIndicator();
                            }
                          }
                      ),

                    ],
                  ),
                ) : new Container(),

              ],
            ),
            //build the graph
            FutureBuilder(
              future: _fetchDataPersonal(selectedType),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  return _buildBody(context);
                } else {
                  return CircularProgressIndicator();
                }
              }
            ),

             //_buildBody(context),

    ]
    )));
  }//, String time


  MassEntry massEntryGenerator(int epochTime, int weight) {

    final df4 = new DateFormat('d MMM yyyy');
    final df5 = new DateFormat('MMM');

    double mass = double.parse(weight.toString());
    DateTime dateTimeValue = DateTime.fromMillisecondsSinceEpoch(epochTime * 1000); //THIS IS FROM EPOCH TIME SO IT IS CORRECT!!!! @ANTHONY
    String timestamp = dateTimeValue.toIso8601String();
    String shortenedTime = df4.format(dateTimeValue).toString();
    String day = dateTimeValue.day.toString();
    String month = df5.format(dateTimeValue).toString();
    String year = dateTimeValue.year.toString();

    return MassEntry(mass, timestamp, shortenedTime, dateTimeValue, day, month, year);
  }

  Widget _buildBody(BuildContext context) {

    List<MassEntry> nextList = list.map((entry) => massEntryGenerator(entry["time"], entry["weight"])).toList();

    return _chooseChart(context, nextList, selectedTime);
  }

  Widget _chooseChart(BuildContext context, List<MassEntry> massdata, String time) {

    switch(time){
      case "week":{

        myData = massdata.where((i)=> DateTime.parse(i.timestamp).isAfter(DateTime(now.year, now.month, now.day).subtract(Duration(days: 6)))  )
            .toList();
        _generateWeeklyData(formatWeekdays(combineDays(myData)));
        //print(DateTime.now().weekday.toString());

        return Expanded(
          child: charts.BarChart(_weekSeriesBarData,
            animate: true, behaviors: [
              new charts.RangeAnnotation([
                new charts.LineAnnotationSegment(
                    personalWeekAverageGeneral, charts.RangeAnnotationAxisType.measure,
                    color: charts.MaterialPalette.purple.shadeDefault),

                new charts.LineAnnotationSegment(
                    areaWeekAverageGeneral, charts.RangeAnnotationAxisType.measure,
                    color: charts.MaterialPalette.teal.shadeDefault),
              ])
            ],
          ),
        );
      }
      break;

      case "month": {
        myData = massdata.where((i)=> (i.dateTimeValue.month == DateTime.now().month)
        && (i.dateTimeValue.year == DateTime.now().year))
            .toList();
        _generateComDayData(fillInDays(combineDays(myData)));
        return Expanded(
          child: charts.BarChart(_seriesBarData,
            animate: true,
          ),
        );
      }
      break;

      case "allTime":{
        myData = massdata;
        _generateTimeChartData(fillInDays(combineDays(myData)));
        return Expanded(
          child: charts.TimeSeriesChart(_timeChartData,
            animate: true,
            defaultRenderer:
            new charts.LineRendererConfig(includeArea: true, stacked: true),
          ),
        );
      }
      break;

      default: {
        //same as today
        myData = massdata.where((i)=> i.shortenedTime == DateFormat('d MMM y').format(DateTime.now()).toString())
            .toList();
        _generateData(myData);
        return Expanded(
          child: charts.BarChart(_seriesBarData,
            animate: true,),
        );
      }
      break;
    }
  }

  List<MassEntry> combineDays(List<MassEntry> rawdata){
    List<MassEntry> output = [];
    if (rawdata.isEmpty) {
      return rawdata;
    }

    for (var i = 0; i < rawdata.length; i++) {

      if (output.where((element) =>
          element.shortenedTime
              == rawdata[i].shortenedTime).isEmpty){
        output.add(rawdata[i]);
      }
      else {
         var x = output.where((element) =>
         element.shortenedTime
             == rawdata[i].shortenedTime).toList()[0];
         var index = output.indexOf(x);
         output[index].mass = output[index].mass + rawdata[i].mass;
      }

    }
    return output;
  }
  
  List<MassEntry> fillInDays(List<MassEntry> rawdata) {
    if (rawdata.isEmpty) {
      return rawdata;
    }

    var now = new DateTime.now();
    final firstEntryDate = rawdata[0].dateTimeValue;
    var timeFromFirstEntryInSeconds = now.difference(firstEntryDate);
    var daysFromStart = timeFromFirstEntryInSeconds.inDays;
    int iteratorIndicator = 0;

    for (var i = 1; i<daysFromStart; i++) {
      var iteratedDateTime = rawdata[0].dateTimeValue.add(Duration(days:i));
      var iteratedShortenedTime = DateFormat('d MMM y').format(iteratedDateTime);
      if (rawdata.firstWhere((e) => e.shortenedTime == iteratedShortenedTime, orElse: () => null) == null) {
        var iteratedMassEntry = new MassEntry(
          0.0,
          iteratedDateTime.toString(),
          iteratedShortenedTime,
          iteratedDateTime,
          DateFormat('d').format(iteratedDateTime).toString(),
          DateFormat('MMM').format(iteratedDateTime).toString(),
          DateFormat('y').format(iteratedDateTime).toString(),
        );
        iteratorIndicator += 1;
        rawdata.insert(iteratorIndicator, iteratedMassEntry);
      } else {
        iteratorIndicator += 1;
      }
    }
    return rawdata;
  }

  List<formattedWeekEntry> formatWeekdays(List<MassEntry> rawdata){
    List<formattedWeekEntry> output = [
      formattedWeekEntry(0,"MON"),
      formattedWeekEntry(0,"TUE"),
      formattedWeekEntry(0,"WED"),
      formattedWeekEntry(0,"THU"),
      formattedWeekEntry(0,"FRI"),
      formattedWeekEntry(0,"SAT"),
      formattedWeekEntry(0,"SUN"),
    ];

    int currentTime = DateTime.now().weekday;

    for ( var i = currentTime; i > 0; i--){
      var x = rawdata.where((element) =>
      element.dateTimeValue.weekday == i);

      if (x.isNotEmpty){
        output[i-1].mass = rawdata[rawdata.indexOf(x.toList()[0])].mass;
      }
    }
    return output;
  }

  Widget _buildStatsDailyInfo(String party) {

    var now = new DateTime.now();
    /*
    List newList = list.map((entry) => massEntryGenerator(entry["time"], entry["weight"]))
        .where((i) => i.shortenedTime == DateFormat('d MMM y')
        .format(DateTime.now()).toString())
        .toList();

    */

    List list1 = list.map((entry) => massEntryGenerator(entry["time"], entry["weight"]))
        .toList();

    List list1_1 = list1.map((entry) => entry.day).toList();

    List list2 = list1.where((entry) => entry.day == now.day.toString()).toList();

    List newList = list2;


    /*
    print("VVVVV");
    print("_buildStatsDailyInfo");
    print(now.day.toString());
    print(list.toString());
    print(list1.toString());
    print(list1_1.toString());
    print(list2.toString());
    print("^^^^^");
    */

    double totalValue = newList.fold(0, (current, entry) => current + entry["weight"]);

    return Expanded(

      child: Text(nf.format(totalValue) + " kg",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width/15,
            fontWeight: FontWeight.bold,
          ),
        ),


    );
  }

  Widget _buildStatsInfo(String party, String trend, Color color) {

    var now = new DateTime.now();
    DateTime date = new DateTime(now.year, now.month);
    DateTime lastDay = Utils.lastDayOfMonth(date);
    int monthDays = lastDay.day;
    double averageValue;

    /*
    print("VVVVV");
    print("_buildStatsInfo");
    print(trend);
    print(type);
    print(list.toString());
    print("^^^^^");
    */

    switch(trend) {

      case "week": {
        averageValue = list.fold(0, (current, entry) => current + entry["weight"]) / 7.0;
      }
      break;

      //for month data
      default: {
        averageValue = list.fold(0, (current, entry) => current + entry["weight"]) / monthDays;
      }
    }

    return Expanded(
        child: Text(nf.format(averageValue) + "kg",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width/25,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        )
    );
  }
}


