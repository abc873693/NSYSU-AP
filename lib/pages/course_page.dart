import 'package:ap_common/models/time_code.dart';
import 'package:ap_common/scaffold/course_scaffold.dart';
import 'package:ap_common/utils/preferences.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/material.dart';
import 'package:nsysu_ap/config/constants.dart';
import 'package:nsysu_ap/models/course_semester_data.dart';
import 'package:nsysu_ap/utils/app_localizations.dart';
import 'package:nsysu_ap/utils/firebase_analytics_utils.dart';
import 'package:nsysu_ap/api/helper.dart';

class CoursePage extends StatefulWidget {
  static const String routerName = "/course";

  @override
  CoursePageState createState() => CoursePageState();
}

class CoursePageState extends State<CoursePage> {
  AppLocalizations app;

  CourseState state = CourseState.loading;

  TimeCodeConfig timeCodeConfig;

  CourseSemesterData semesterData;
  CourseData courseData;

  List<String> items;
  int semesterIndex = 0;

  bool isOffline = false;

  @override
  void initState() {
    super.initState();
    FA.setCurrentScreen("CoursePage", "course_page.dart");
    _getSemester();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    app = AppLocalizations.of(context);
    return CourseScaffold(
      state: state,
      courseData: courseData,
      semesterIndex: semesterIndex,
      semesters: items,
      onSelect: (index) {
        this.semesterIndex = index;
        _getCourseTables();
      },
      onRefresh: _getCourseTables,
      isOffline: isOffline,
    );
  }

  void _getSemester() async {
    semesterData = await Helper.instance.getCourseSemesterData();
    final RemoteConfig remoteConfig = await RemoteConfig.instance;
    try {
      await remoteConfig.fetch(expiration: const Duration(seconds: 10));
      await remoteConfig.activateFetched();
    } catch (exception) {
      semesterData.setDefault(
        Preferences.getString(Constants.DEFAULT_COURSE_SEMESTER_CODE, '1082'),
      );
      timeCodeConfig = TimeCodeConfig.fromRawJson(
        Preferences.getString(
          Constants.TIME_CODE_CONFIG,
          '{  "timeCodes":[{"title":"A",         "startTime": "7:00"         ,"endTime": "7:50"        },{       "title":"1",         "startTime": "8:10"         ,"endTime": "9:00"        },{       "title":"2",         "startTime": "9:10"         ,"endTime": "10:00"        },{       "title":"3",         "startTime": "10:10"         ,"endTime": "11:00"        },{       "title":"4",         "startTime": "11:10"         ,"endTime": "12:00"        },{       "title":"B",         "startTime": "12:10"         ,"endTime": "13:00"        },{       "title":"5",         "startTime": "13:10"         ,"endTime": "14:00"        },{       "title":"6",         "startTime": "14:10"         ,"endTime": "15:00"        },{       "title":"7",         "startTime": "15:10"         ,"endTime": "16:00"        },{       "title":"8",         "startTime": "16:10"         ,"endTime": "17:00"        },{       "title":"9",         "startTime": "17:10"         ,"endTime": "18:00"        },{       "title":"C",         "startTime": "18:20"         ,"endTime": "19:10"        },{       "title":"D",         "startTime": "19:15"         ,"endTime": "20:05"        },{       "title":"E",         "startTime": "20:10"         ,"endTime": "21:00"        },{       "title":"F",         "startTime": "21:05"         ,"endTime": "21:55"        }] }',
        ),
      );
    } finally {
      String code =
          remoteConfig.getString(Constants.DEFAULT_COURSE_SEMESTER_CODE);
      String rawTimeCodeConfig =
          remoteConfig.getString(Constants.TIME_CODE_CONFIG);
      timeCodeConfig = TimeCodeConfig.fromRawJson(rawTimeCodeConfig);
      semesterData.setDefault(code);
      Preferences.setString(Constants.DEFAULT_COURSE_SEMESTER_CODE, code);
      Preferences.setString(Constants.TIME_CODE_CONFIG, rawTimeCodeConfig);
      items = [];
      var i = 0;
      semesterData.semesters.forEach((option) {
        items.add(parser(option.text));
        if (option.value == code) semesterIndex = i;
        i++;
      });
    }
    _getCourseTables();
  }

  String parser(String text) {
    if (text.length == 4) {
      String lastCode = text.substring(3);
      String last = '';
      switch (lastCode) {
        case '0':
          last = app.continuingSummerEducationProgram;
          break;
        case '1':
          last = app.fallSemester;
          break;
        case '2':
          last = app.springSemester;
          break;
        case '3':
          last = app.summerSemester;
          break;
      }
      String first;
      if (AppLocalizations.locale.languageCode == 'en') {
        int year = int.parse(text.substring(0, 3));
        year += 1911;
        first = '$year~${year + 1}';
      } else
        first = '${text.substring(0, 3)}${app.courseYear}';
      return '$first $last';
    } else
      return text;
  }

  _getCourseTables() async {
    setState(() {
      state = CourseState.loading;
    });
    Helper.instance
        .getCourseData(
      Preferences.getString(Constants.PREF_USERNAME, ''),
      timeCodeConfig,
      semesterData.semesters[semesterIndex].value,
    )
        .then((courseData) {
      this.courseData = courseData;
      if (mounted)
        setState(() {
          if (this.courseData.courseTables == null)
            state = CourseState.empty;
          else
            state = CourseState.finish;
        });
    });
  }
}
