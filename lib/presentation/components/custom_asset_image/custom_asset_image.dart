import 'package:elostaz_travel/core/extensions/extensions.dart';
import 'package:flutter/material.dart';

class CustomAssetImage extends StatelessWidget {
  final String assetName;
  final double? width;
  final double? height;
  final BoxFit? boxFit;

  const CustomAssetImage({super.key,required this.assetName,this.width,this.height,this.boxFit});

  @override
  Widget build(BuildContext context) {
    return Image.asset(assetName.startsWith('assets')?assetName:'assets/images/icons/$assetName.png',width: width??20.w,height: height??20.w,fit: boxFit??BoxFit.cover,);
  }
}
