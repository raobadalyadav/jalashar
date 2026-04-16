enum MetaFieldType { text, number, multiselect }

class MetaField {
  final String key;
  final String label;
  final MetaFieldType type;
  final List<String> options;

  const MetaField({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
  });
}

class VendorCategoryMeta {
  static const Map<String, List<MetaField>> _fields = {
    'photographer': [
      MetaField(
        key: 'shooting_styles', label: 'Shooting Styles',
        type: MetaFieldType.multiselect,
        options: ['Candid', 'Traditional', 'Pre-wedding', 'Maternity', 'Events', 'Portfolio'],
      ),
      MetaField(
        key: 'equipment', label: 'Equipment',
        type: MetaFieldType.multiselect,
        options: ['Canon R5', 'Sony A7IV', 'Nikon Z8', 'Fujifilm XT5', 'Drone', 'Studio Lights'],
      ),
      MetaField(key: 'editing_style', label: 'Editing Style', type: MetaFieldType.text),
      MetaField(key: 'delivery_days', label: 'Delivery Time (days)', type: MetaFieldType.number),
    ],
    'videographer': [
      MetaField(
        key: 'editing_styles', label: 'Editing Styles',
        type: MetaFieldType.multiselect,
        options: ['Cinematic', 'Documentary', 'Highlights Reel', 'Live Streaming', 'Drone Shots'],
      ),
      MetaField(
        key: 'equipment', label: 'Equipment',
        type: MetaFieldType.multiselect,
        options: ['4K Camera', '6K+ Camera', 'Drone', 'Gimbal', 'LED Lighting', 'Steadicam'],
      ),
      MetaField(key: 'delivery_days', label: 'Delivery Time (days)', type: MetaFieldType.number),
    ],
    'makeup': [
      MetaField(
        key: 'makeup_styles', label: 'Makeup Styles',
        type: MetaFieldType.multiselect,
        options: ['Bridal', 'HD Makeup', 'Airbrush', 'Party', 'Editorial', 'Natural Glow'],
      ),
      MetaField(
        key: 'products_used', label: 'Brands Used',
        type: MetaFieldType.multiselect,
        options: ['MAC', 'NARS', 'Huda Beauty', 'Kiko', 'Lakme', 'Kay Beauty', 'Charlotte Tilbury'],
      ),
      MetaField(key: 'includes_trial', label: 'Trial Session Offered (Yes/No)', type: MetaFieldType.text),
    ],
    'mehendi': [
      MetaField(
        key: 'mehendi_styles', label: 'Mehendi Styles',
        type: MetaFieldType.multiselect,
        options: ['Arabic', 'Rajasthani', 'Bridal Full', 'Indo-Arabic', 'Pattern', 'Tikki'],
      ),
      MetaField(key: 'includes_both_hands', label: 'Both Hands Included (Yes/No)', type: MetaFieldType.text),
    ],
    'caterer': [
      MetaField(
        key: 'cuisine_types', label: 'Cuisine Types',
        type: MetaFieldType.multiselect,
        options: ['North Indian', 'South Indian', 'Chinese', 'Continental', 'Mughlai', 'Street Food', 'Sweets & Desserts'],
      ),
      MetaField(
        key: 'service_types', label: 'Service Styles',
        type: MetaFieldType.multiselect,
        options: ['Buffet', 'Plated Service', 'Live Stations', 'Outdoor Catering', 'Home Delivery'],
      ),
      MetaField(key: 'per_plate_veg', label: 'Per Plate Veg (₹)', type: MetaFieldType.number),
      MetaField(key: 'per_plate_nonveg', label: 'Per Plate Non-Veg (₹)', type: MetaFieldType.number),
      MetaField(key: 'min_guests', label: 'Minimum Guests', type: MetaFieldType.number),
    ],
    'dj': [
      MetaField(
        key: 'music_genres', label: 'Music Genres',
        type: MetaFieldType.multiselect,
        options: ['Bollywood', 'EDM', 'Hip-Hop', 'Pop', 'Classical', 'Remixes', 'Bhangra', 'Sufi'],
      ),
      MetaField(key: 'equipment', label: 'Equipment Details', type: MetaFieldType.text),
      MetaField(key: 'sound_wattage', label: 'Sound System (Watts)', type: MetaFieldType.text),
    ],
    'decorator': [
      MetaField(
        key: 'decoration_styles', label: 'Decoration Styles',
        type: MetaFieldType.multiselect,
        options: ['Floral', 'LED Lights', 'Balloon Art', 'Theme Decor', 'Minimalist', 'Royal', 'Rustic'],
      ),
      MetaField(key: 'event_themes', label: 'Signature Themes (describe)', type: MetaFieldType.text),
    ],
    'band': [
      MetaField(
        key: 'genres', label: 'Music Genres',
        type: MetaFieldType.multiselect,
        options: ['Bollywood', 'Classical', 'Pop', 'Ghazal', 'Folk', 'Fusion', 'Jazz'],
      ),
      MetaField(key: 'band_type', label: 'Band Type (e.g. Brass, Pop, Ghazal)', type: MetaFieldType.text),
      MetaField(key: 'member_count', label: 'Number of Members', type: MetaFieldType.number),
    ],
    'florist': [
      MetaField(
        key: 'flower_types', label: 'Flower Types',
        type: MetaFieldType.multiselect,
        options: ['Rose', 'Jasmine', 'Marigold', 'Orchid', 'Lily', 'Mixed Seasonal'],
      ),
      MetaField(
        key: 'arrangement_styles', label: 'Arrangement Styles',
        type: MetaFieldType.multiselect,
        options: ['Bouquet', 'Garland', 'Centrepiece', 'Arch', 'Stage Decor', 'Car Decoration'],
      ),
    ],
    'pandit': [
      MetaField(
        key: 'pooja_types', label: 'Pooja / Ceremony Types',
        type: MetaFieldType.multiselect,
        options: ['Vivah', 'Satyanarayan', 'Griha Pravesh', 'Mundane', 'Namkaran', 'Ganesh Puja', 'Havan'],
      ),
      MetaField(
        key: 'languages', label: 'Languages',
        type: MetaFieldType.multiselect,
        options: ['Sanskrit', 'Hindi', 'English', 'Marathi', 'Tamil', 'Telugu', 'Kannada'],
      ),
    ],
  };

  static List<MetaField> forCategory(String category) =>
      _fields[category.toLowerCase()] ?? [];

  static bool hasFields(String category) =>
      _fields.containsKey(category.toLowerCase());
}
