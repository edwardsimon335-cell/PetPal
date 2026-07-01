class AppAssets {
  const AppAssets._();

  static const roomScene = 'assets/backgrounds/room_scene.png';
  static const logo = 'assets/branding/petpal_logo.png';
  static const roomItemFoodBowl = 'assets/room_items/food_bowl.png';
  static const roomItemSoftBlanket = 'assets/room_items/soft_blanket.png';
  static const roomItemToyBall = 'assets/room_items/toy_ball.png';
  static const roomItemCatBox = 'assets/room_items/cat_box.png';
  static const roomItemWindowCushion = 'assets/room_items/window_cushion.png';
  static const nuonuoIdle = 'assets/pets/nuonuo/nuonuo_idle.png';
  static const nuonuoWalk = 'assets/pets/nuonuo/nuonuo_walk.png';
  static const nuonuoSleep = 'assets/pets/nuonuo/nuonuo_sleep.png';
  static const nuonuoEat = 'assets/pets/nuonuo/nuonuo_eat.png';
  static const nuonuoHappy = 'assets/pets/nuonuo/nuonuo_happy.png';
  static const nuonuoAttentive = 'assets/pets/nuonuo/nuonuo_attentive.png';

  static String? roomItemAssetFor(String itemId) {
    switch (itemId) {
      case 'food_bowl':
        return roomItemFoodBowl;
      case 'soft_blanket':
        return roomItemSoftBlanket;
      case 'toy_ball':
        return roomItemToyBall;
      case 'cat_box':
        return roomItemCatBox;
      case 'window_cushion':
        return roomItemWindowCushion;
    }
    return null;
  }
}
