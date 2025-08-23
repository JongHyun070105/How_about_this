import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:review_ai/config/security_config.dart';

// 1. Define the state for the ad service
class AdState {
  final RewardedAd? rewardedAd;
  final bool isAdLoaded;

  AdState({this.rewardedAd, this.isAdLoaded = false});

  AdState copyWith({RewardedAd? rewardedAd, bool? isAdLoaded}) {
    return AdState(
      rewardedAd: rewardedAd, // No null check, allow setting to null
      isAdLoaded: isAdLoaded ?? this.isAdLoaded,
    );
  }
}

// 2. Create the StateNotifier
class AdService extends StateNotifier<AdState> {
  AdService() : super(AdState()) {
    loadAd();
  }

  Future<void> loadAd() async {
    if (state.isAdLoaded) return;

    await RewardedAd.load(
      adUnitId: SecurityConfig.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _configureAdCallbacks(ad);
          state = state.copyWith(rewardedAd: ad, isAdLoaded: true);
        },
        onAdFailedToLoad: (error) {
          state = state.copyWith(rewardedAd: null, isAdLoaded: false);
          debugPrint('Ad failed to load: $error');
        },
      ),
    );
  }

  void _configureAdCallbacks(RewardedAd ad) {
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        state = state.copyWith(rewardedAd: null, isAdLoaded: false);
        loadAd(); // Pre-load next ad
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('Rewarded ad failed to show: $error');
        ad.dispose();
        state = state.copyWith(rewardedAd: null, isAdLoaded: false);
        loadAd(); // Pre-load next ad
      },
    );
  }

  Future<bool> showAdWithRetry({
    required Function onUserEarnedReward,
    required Function(String) onAdFailedToLoad,
  }) async {
    for (int i = 0; i < 3; i++) {
      if (state.isAdLoaded) {
        await showAd(onUserEarnedReward: onUserEarnedReward);
        return true;
      }

      onAdFailedToLoad('광고를 불러오는 중입니다... (${i + 1}/3)');
      await loadAd();

      if (i < 2) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }

    if (state.isAdLoaded) {
      await showAd(onUserEarnedReward: onUserEarnedReward);
      return true;
    }

    return false;
  }

  Future<void> showAd({required Function onUserEarnedReward}) async {
    if (!state.isAdLoaded) {
      debugPrint('Ad not ready.');
      return;
    }

    await state.rewardedAd!.show(
      onUserEarnedReward: (ad, reward) {
        onUserEarnedReward();
      },
    );
    // The onAdDismissed callback will handle state updates
  }

  @override
  void dispose() {
    state.rewardedAd?.dispose();
    super.dispose();
  }
}

// 3. Create the provider
final adServiceProvider = StateNotifierProvider<AdService, AdState>((ref) {
  return AdService();
});