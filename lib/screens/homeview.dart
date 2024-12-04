import 'dart:typed_data';

import 'package:appinio_swiper/appinio_swiper.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final AppinioSwiperController controller = AppinioSwiperController();

  List<AssetEntity> _mediaList = [];
  bool _isLoading = true;
  int _currentPage = 0;
  final int _pageSize = 20;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _fetchMedia();
  }

  // Fetch images from the gallery
  Future<void> _fetchMedia({bool isLoadMore = false}) async {
    if (!isLoadMore) {
      setState(() {
        _isLoading = true;
      });
    }

    final PermissionState permissionState =
    await PhotoManager.requestPermissionExtend();

    if (permissionState.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        onlyAll: true,
      );

      if (albums.isNotEmpty) {
        List<AssetEntity> media = await albums.first.getAssetListPaged(
          page: _currentPage,
          size: _pageSize,
        );

        setState(() {
          _mediaList.addAll(media);
          _isLoading = false;
          _hasMore = media.isNotEmpty;
          if (isLoadMore) _currentPage++;
        });
      }
    } else {
      PhotoManager.openSetting();
    }
  }

  // Delete all photos from the gallery
  // Future<void> _deleteAllPhotos() async {
  //   for (var media in _mediaList) {
  //     await media.deleteFromGallery(); // Deletes the photo from the gallery
  //   }
  //   setState(() {
  //     _mediaList.clear(); // Clear the local list
  //   });
  // }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : CupertinoPageScaffold(
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.75,
                  child: AppinioSwiper(
                    controller: controller,
                    cards: List.generate(
                      _mediaList.length,
                          (index) {
                        final media = _mediaList[index];
                        return FutureBuilder<Uint8List?>(
                          future: media.thumbnailData,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                              return Image.memory(
                                snapshot.data!,
                                fit: BoxFit.contain,
                              );
                            }
                            return Container(
                              width: double.infinity,
                              height: double.infinity,
                              color: Colors.grey,
                            );
                          },
                        );
                      },
                    ),
                    onSwipe: _onSwipe,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _onSwipe(int previousIndex, int? currentIndex, AppinioSwiperDirection direction) {
    debugPrint(
      'The card $previousIndex was swiped to the ${direction.name}. Now the card $currentIndex is on top',
    );

    if (direction == AppinioSwiperDirection.left) {
      // _deleteAllPhotos(); // Delete all photos when swiping left
      return false; // Prevent further swipes since the list will be cleared
    }

    return true;
  }

  bool _onUndo(int? previousIndex, int currentIndex, AppinioSwiperDirection direction) {
    debugPrint(
      'The card $currentIndex was undone from the ${direction.name}',
    );
    return true;
  }
}