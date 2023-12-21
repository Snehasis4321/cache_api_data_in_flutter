import 'package:cache_api_data_in_flutter/controllers/fetch_api.dart';
import 'package:cache_api_data_in_flutter/controllers/local_database.dart';
import 'package:cache_api_data_in_flutter/models/models.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:url_launcher/url_launcher.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  ScrollController _scrollController = ScrollController();
  List<HackerNews> latestNews = [];
  bool isLoading = true;
  bool isMoreNewsLoading = false;
  List<Map<String, dynamic>> savedTime = [];
  int current_page = 0;

  // get all the times with page where saved to database
  getLastSavedTime() async {
    var time = await LocalDatabase.getSaveTime();
    setState(() {
      savedTime = time;
    });
  }

  // read news from db or fetch api
  firstPageNews() async {
    int count = await LocalDatabase.getNewsCount() ?? 0;
    print("No of news saved ${count}");
    int savedTimeLength = savedTime.length;
    DateTime firstPageSavedTime = savedTimeLength >= 1
        ? DateTime.parse(savedTime[0]["lastSavedTime"] ?? "2000-01-01")
        : DateTime(2000);

    print(firstPageSavedTime);

    DateTime currentTime = DateTime.now();

    Duration difference = currentTime.difference(firstPageSavedTime);
    if (difference.inMinutes > 5 || count == 0) {
      print("fetching the api");
      var isApifetching = await HackerNewsApi.getLatestHackerNews(current_page);
      if (isApifetching) {
        getNews();
      }
    } else {
      print("data from local database");
      getNews();
    }
  }

// next page news
  nextPageNews() async {
    setState(() {
      isMoreNewsLoading = true;
    });
    int count = await LocalDatabase.getNewsCount() ?? 0;
    print("No of news saved ${count}");
    await getLastSavedTime();
    int savedTimeLength = savedTime.length;
    DateTime nextPageSavedTime = current_page > savedTimeLength - 1
        ? DateTime(2000)
        : DateTime.parse(
            savedTime[current_page]["lastSavedTime"] ?? "2000-01-01");

    print(nextPageSavedTime);

    DateTime currentTime = DateTime.now();

    Duration difference = currentTime.difference(nextPageSavedTime);
    if (difference.inMinutes > 5) {
      print("fetching the api for $current_page");
      var isApifetching = await HackerNewsApi.getLatestHackerNews(current_page);
      if (isApifetching) {
        getMoreNews();
      }
    } else {
      print("data from local database");
      getMoreNews();
    }
  }

// read data from local database
  getNews() async {
    var news = await LocalDatabase.getNews();
    setState(() {
      latestNews = news.map((e) => HackerNews.fromJson(e)).toList();
      isLoading = false;
    });
  }

  // get more news from local database
  getMoreNews() async {
    var news = await LocalDatabase.getMoreNews(latestNews.length);
    setState(() {
      latestNews.addAll(news.map((e) => HackerNews.fromJson(e)).toList());
      isMoreNewsLoading = false;
    });
  }

  // to load more news on scroll
  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      current_page++;
      nextPageNews();
    }
  }

  @override
  void initState() {
    getLastSavedTime();
    firstPageNews();
    _scrollController.addListener(_scrollListener);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Hacker News"),
        centerTitle: true,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(),
            )
          : latestNews.isEmpty
              ? Center(child: Text("No News Found"))
              : ListView.builder(
                  controller: _scrollController,
                  itemCount: latestNews.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: Text("${index + 1}."),
                      title: Text(latestNews[index].title),
                      subtitle: Text("By ${latestNews[index].author}"),
                      trailing: IconButton(
                        icon: Icon(Icons.open_in_new),
                        onPressed: () {
                          _launchUrl(latestNews[index].url);
                        },
                      ),
                    );
                  },
                ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
                onPressed: () {
                  getLastSavedTime();
                  firstPageNews();
                  current_page = 0;

                  setState(() {
                    isLoading = true;
                  });
                },
                child: Icon(Icons.refresh)),
            SizedBox(
              width: 10,
            ),
            FloatingActionButton(
                onPressed: () {
                  LocalDatabase.deleteAllNews();
                  LocalDatabase.deleteSavedTime();
                  setState(() {
                    latestNews = [];
                  });
                },
                child: Icon(Icons.delete)),
          ],
        ),
      ),
      bottomNavigationBar: isMoreNewsLoading
          ? SizedBox(
              height: 55, child: Center(child: CircularProgressIndicator()))
          : null,
    );
  }
}

Future<void> _launchUrl(String _url) async {
  if (!await launchUrl(Uri.parse(_url))) {
    throw Exception('Could not launch $_url');
  }
}
