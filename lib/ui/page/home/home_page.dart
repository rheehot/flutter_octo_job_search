import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_octo_job_search/bloc/job/job_bloc.dart';
import 'package:flutter_octo_job_search/bloc/job/job_model.dart';
import 'package:flutter_octo_job_search/bloc/theme/theme_bloc.dart';
import 'package:flutter_octo_job_search/helper/dummy_data.dart';
import 'package:flutter_octo_job_search/ui/page/home/widget/filter_dialog.dart';
import 'package:flutter_octo_job_search/ui/page/home/widget/job_tile.dart';
import 'package:flutter_octo_job_search/ui/page/settings.dart';
import 'package:flutter_octo_job_search/ui/theme/theme.dart';
import 'package:flutter_octo_job_search/ui/widget/erorr_widget.dart';

class HomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<HomePage> {
  List<JobModel> list;
  ValueNotifier<bool> isFullTime = ValueNotifier<bool>(false);
  TextEditingController location;
  TextEditingController description;
  @override
  ScrollController _controller;
  void initState() {
    location = TextEditingController();
    description = TextEditingController();
    _controller = ScrollController()..addListener(listener);
    super.initState();
    list = [];
    BlocProvider.of<JobBloc>(context)..add(LoadJobsList());
    DummyData.data.forEach((map) {
      var model = JobModel.fromJson(map);
      list.add(model);
    });
  }

  

  void listener() {
    if (_controller.position.pixels == _controller.position.maxScrollExtent) {
      BlocProvider.of<JobBloc>(context)..add(SearchNextJobs(description.text, isFullTime.value, location.text,isLoadNextJobs: true));
    }
  }

  void displayFilterJob() async {
    description.clear();
    await showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            height: 210,
            alignment: Alignment.center,
            child: FilterDialog(
              isFullTime: isFullTime,
              controller: location,
              onSearchTap: (loc) {
                print("Call api");
                BlocProvider.of<JobBloc>(context)..add(SearchJobBy(description.text, isFullTime.value, loc));
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      appBar: AppBar(
        elevation: 0,
        title: Text("  Octo Job Search"),
        actions: [
          BlocBuilder<ThemeBloc, ThemeState>(
            builder: (context, state) {
              return IconButton(
                icon: Icon(Icons.dehaze_outlined),
                onPressed: () {
                  Navigator.push(context, SettingsPage.getPageRoute());
                  // if (state is LoadedTheme) {
                  //   var type = state.type == ThemeType.DARK ? ThemeType.LIGHT : ThemeType.DARK;
                  //   BlocProvider.of<ThemeBloc>(context)..add(OnThemeChange(type));
                  // }
                },
              );
            },
          ),
          SizedBox(
            width: 10,
          )
        ],
      ),
      body: Container(
        child: Column(
          children: [
            Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: 35,
                    width: double.infinity,
                    color: theme.primaryColor,
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: 60,
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: theme.cardColor,
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search, color: theme.primaryColor),
                        Expanded(
                          child: TextField(
                            decoration: InputDecoration(border: InputBorder.none, hintText: "Filter by text"),
                          ),
                        ),
                        Icon(Icons.filter_alt).p(8).ripple(() {
                          displayFilterJob();
                        }),
                        // SizedBox(width:8),
                        Container(
                          color: theme.primaryColor,
                          child: Icon(Icons.search, color: theme.colorScheme.onPrimary).p(8),
                        ).cornerRadius(5).ripple(() {
                          FocusManager.instance.primaryFocus.unfocus();
                          BlocProvider.of<JobBloc>(context)..add(SearchJobBy(description.text, null, null));
                        })
                      ],
                    ),
                  ),
                )
              ],
            ),
            if (list != null)
              BlocBuilder<JobBloc, JobState>(
                builder: (context, state) {
                  if (state is LoadedJobsList) {
                    list = state.jobs;
                  }
                  if (state is OnJobLoading) {
                    return Container(
                      height: AppTheme.fullHeight(context) - 150,
                      alignment: Alignment.center,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(theme.primaryColor),
                        strokeWidth: 4,
                      ),
                    );
                  } else if (state is ErrorJobListState) {
                    return Container(
                      height: AppTheme.fullHeight(context) - 350,
                      child: GErrorContainer(
                        title: "Some error occured",
                        description: "Try again in some time",
                      ),
                    );
                  }
                  return ListView.builder(
                    controller: _controller,
                    physics: BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(vertical: 16),
                    itemCount: list.length + 1,
                    itemBuilder: (_, index) {
                      if(index == list.length){
                        if(state is OnNextJobLoading){
                          return CircularProgressIndicator();
                        }
                        return SizedBox.shrink();
                      }
                      return JobTile(model: list[index]);
                    },
                  ).extended;
                },
              )
          ],
        ),
      ),
    );
  }
}
