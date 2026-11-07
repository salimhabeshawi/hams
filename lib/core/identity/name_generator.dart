// SPDX-License-Identifier: GPL-3.0-or-later
import 'dart:math';

const adjectives = <String>[
  'Happy','Sunny','Gentle','Bright','Cheerful','Cozy','Breezy','Mellow','Jolly','Swift','Calm','Merry','Playful','Sparkly','Fluffy','Dreamy','Peaceful','Brave','Clever','Humble','Lively','Radiant','Misty','Golden','Silver','Velvet','Wise','Kind','Graceful','Glowing','Serene','Zesty','Fresh','Dewy','Bubbly','Tidy','Snug','Rosy','Sweet','Tender','Noble','Bold','Eager','Nimble','Chipper','Perky','Soaring','Shining','Twinkling','Hopeful','Joyful','Smiling','Curious','Friendly','Honest','Patient','Steady',
];
const nouns = <String>[
  'Mango','Papaya','Guava','Pomegranate','Apricot','Fig','Lemon','Orange','Apple','Pear','Plum','Melon','Kiwi','Lime','Coconut','Pineapple','Blueberry','Strawberry','Tangerine','Peach','Avocado','Raspberry','Mulberry','Clementine','Lychee','Watermelon','Banana','Jasmine','Lily','Daisy','Tulip','Orchid','Lotus','Sunflower','Lavender','Violet','Marigold','Iris','Blossom','Peony','Magnolia','Hibiscus','Clover','Fern','Mint','Basil','Sage','Bamboo','Acacia','Cedar','Olive','Palm','Maple','Willow','Juniper','Cypress','Meadow','River','Waterfall','Canyon','Valley','Lagoon','Breeze','Cloud','Rainbow','Sunrise','Sunbeam','Dawn','Moonbeam','Comet','Aurora','Dune','Oasis','Island','Reef','Pebble','Coral','Pearl','Opal','Amber','Jade','Ruby','Topaz','Crystal','Sapphire','Emerald','Garnet','Glacier','Brook','Creek','Harbor','Horizon','Hilltop','Orchard','Garden','Grove','Prairie','Snowflake','Raindrop','Dewdrop','Starlight','Sparrow','Falcon','Dove','Swan','Robin','Finch','Heron','Pelican','Butterfly','Firefly','Dolphin','Bluebird','Skylark','Starling','Ladybug','Dragonfly',
];

class NameGenerator {
  NameGenerator([Random? random]) : _random = random ?? Random();
  final Random _random;
  String generate() => '${adjectives[_random.nextInt(adjectives.length)]} ${nouns[_random.nextInt(nouns.length)]}';
}

class NameValidator {
  static final _allowed = RegExp(r\"^[A-Za-z0-9 '-]+$\");
  static final _blocked = <String>{
    'alcohol','beer','wine','pork','pig','dog','gamble','luck','music','dance','weapon','violence','hate','kill','dark','scary',
  };
  static String normalize(String value) => value.trim().replaceAll(RegExp(r'\\s+'), ' ');
  static String? validate(String value) {
    final normalized = normalize(value);
    if (normalized.length < 2 || normalized.length > 24) return 'Name must be 2–24 characters.';
    if (!_allowed.hasMatch(normalized)) return 'Use letters, numbers, spaces, hyphens, or apostrophes.';
    final compact = normalized.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (_blocked.any(compact.contains)) return 'Please choose a friendly name.';
    return null;
  }
}
