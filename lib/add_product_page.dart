import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'success_page.dart';
import 'app_theme.dart';
import 'models/categories.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_storage/firebase_storage.dart';

class AddProductPage extends StatefulWidget {
  final String? postId;
  final Map<String, dynamic>? postData;

  const AddProductPage({
    super.key,
    this.postId,
    this.postData,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();

  String? selectedCategory;
  String? selectedCondition;
  String? selectedCollege;
  String? selectedStudyYear;
  String? selectedSubCategory;
  File? selectedImage;
  String? existingImageUrl;
  String? _imageUrl;
  bool _isLoading = false;
  final picker = ImagePicker();

  // Using unified categories from categories.dart
  List<String> get _categories => kAppCategories
      .where((cat) => cat['label'] != 'All') // Exclude 'All' category
      .map((cat) => cat['label'] as String)
      .toList();

  final List<String> _conditions = [
    'New',
    'Excellent',
    'Good',
    'Fair',
  ];

  final List<String> _colleges = [
    'collegeOfEngineering',
    'collegeOfMedicine',
    'collegeOfDentistry',
    'collegeOfScience',
    'collegeOfArts',
    'collegeOfBusiness',
    'collegeOfEducation',
    'collegeOfComputerScience',
    'collegeOfArchitecture',
    'collegeOfPharmacy',
  ];

  final List<String> _studyYears = [
    'firstYear',
    'secondYear',
    'thirdYear',
    'fourthYear',
    'fifthYear',
    'sixthYear',
    'graduateStudent',
  ];

  List<String> get _subCategories {
    switch (selectedCollege) {
      case 'collegeOfEngineering':
        return ['engineeringTools', 'labEquipment', 'drawingTools', 'calculators', 'textbooks'];
      case 'collegeOfMedicine':
        return ['medicalEquipment', 'labCoats', 'stethoscopes', 'medicalBooks', 'surgicalTools'];
      case 'collegeOfDentistry':
        return ['dentalEquipment', 'dentalTools', 'dentalBooks', 'dentalSupplies'];
      case 'collegeOfScience':
        return ['scienceEquipment', 'microscopes', 'labSupplies', 'scienceBooks'];
      case 'collegeOfArts':
        return ['artSupplies', 'drawingMaterials', 'paintings', 'crafts'];
      case 'collegeOfBusiness':
        return ['businessBooks', 'businessTools', 'presentationMaterials'];
      case 'collegeOfEducation':
        return ['teachingMaterials', 'educationalBooks', 'classroomSupplies'];
      case 'collegeOfComputerScience':
        return ['computerParts', 'programmingBooks', 'electronics'];
      case 'collegeOfArchitecture':
        return ['architecturalTools', 'drawingBoards', 'architecturalBooks'];
      case 'collegeOfPharmacy':
        return ['pharmacyEquipment', 'pharmacyBooks', 'labMaterials'];
      default:
        return [];
    }
  }

  bool get isEditing => widget.postId != null;

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.postData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.postData!;
    _nameCtrl.text = data['name'] ?? '';
    _descCtrl.text = data['description'] ?? '';
    _priceCtrl.text = data['price']?.toString() ?? '';
    _locationCtrl.text = data['location'] ?? '';
    selectedCategory = data['category'];
    selectedCondition = data['condition'];
    selectedCollege = data['college'];
    selectedStudyYear = data['studyYear'];
    selectedSubCategory = data['subCategory'];
    existingImageUrl = data['imageUrl'];
  }

  Future<void> _pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => selectedImage = File(picked.path));
    }
  }

  Future<String> _uploadImageToCloudinary(File image) async {
    const cloudName = 'doih6vdac';
    const preset = 'unsigned_preset';
    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    var request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = preset
      ..files.add(await http.MultipartFile.fromPath('file', image.path));

    final res = await request.send();
    final responseBody = await res.stream.bytesToString();
    return json.decode(responseBody)['secure_url'];
  }

  Future<void> _uploadImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        setState(() {
          _isLoading = true;
        });

        final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final Reference ref = FirebaseStorage.instance.ref().child('product_images/$fileName');
        final UploadTask uploadTask = ref.putFile(File(image.path));
        final TaskSnapshot snapshot = await uploadTask;
        final String downloadUrl = await snapshot.ref.getDownloadURL();

        setState(() {
          _imageUrl = downloadUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate() ||
        (selectedImage == null && existingImageUrl == null) ||
        selectedCategory == null ||
        selectedCondition == null ||
        selectedCollege == null ||
        selectedStudyYear == null ||
        selectedSubCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.pleaseCompleteAllFields)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppTheme.primaryBlue)),
    );

    try {
      String imageUrl = existingImageUrl ?? '';
      
      if (selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(selectedImage!);
      }

      final user = FirebaseAuth.instance.currentUser;
      
      if (isEditing) {
        final updateData = {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'imageUrl': imageUrl,
          'category': selectedCategory,
          'condition': selectedCondition,
          'college': selectedCollege,
          'studyYear': selectedStudyYear,
          'subCategory': selectedSubCategory,
        };
        
        await FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.postId)
            .update(updateData);
      } else {
        final newPostData = {
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'location': _locationCtrl.text.trim(),
          'imageUrl': imageUrl,
          'category': selectedCategory,
          'condition': selectedCondition,
          'college': selectedCollege,
          'studyYear': selectedStudyYear,
          'subCategory': selectedSubCategory,
          'ownerId': user?.uid ?? '',
          'ownerName': user?.displayName ?? '',
          'ownerAvatar': user?.photoURL ?? '',
          'timestamp': FieldValue.serverTimestamp(),
          'likesCount': 0,
          'likedBy': [],
        };
        
        await FirebaseFirestore.instance.collection('posts').add(newPostData);
      }

      if (mounted) {
        Navigator.pop(context); // Close loading
        
        if (isEditing) {
          Navigator.pop(context); // Return to details page
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.productUpdated),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const SuccessPage()),
          );
        }
      }
    } catch (e) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n.errorMessage}: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppWidgets.buildAppBar(
        title: isEditing ? l10n.edit : l10n.addNewPost,
      ),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppTheme.borderGrey,
                    borderRadius: BorderRadius.circular(12),
                    image: selectedImage != null
                        ? DecorationImage(image: FileImage(selectedImage!), fit: BoxFit.cover)
                        : existingImageUrl != null
                            ? DecorationImage(image: NetworkImage(existingImageUrl!), fit: BoxFit.cover)
                            : null,
                  ),
                  child: (selectedImage == null && existingImageUrl == null)
                      ? const Center(child: Icon(Icons.add_a_photo, size: 40, color: AppTheme.mediumGrey))
                      : Stack(
                          children: [
                            if (selectedImage != null || existingImageUrl != null)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(Icons.edit, color: Colors.white),
                                    onPressed: _pickImage,
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 16),

              _buildTextField(controller: _nameCtrl, label: l10n.productName),
              const SizedBox(height: 12),
              _buildTextField(controller: _priceCtrl, label: l10n.price, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _buildTextField(controller: _descCtrl, label: l10n.description, maxLines: 3),
              const SizedBox(height: 12),
              _buildTextField(controller: _locationCtrl, label: l10n.location),

              const SizedBox(height: 16),
              _buildDropdown(
                l10n.category,
                _categories,
                selectedCategory,
                (val) {
                  setState(() => selectedCategory = val);
                },
              ),

              const SizedBox(height: 12),
              _buildDropdown(l10n.condition, _conditions, selectedCondition, (val) {
                setState(() => selectedCondition = val);
              }),

              const SizedBox(height: 12),
              _buildDropdown(
                l10n.college,
                _colleges,
                selectedCollege,
                (val) {
                  setState(() {
                    selectedCollege = val;
                    selectedSubCategory = null; // Reset sub-category when college changes
                  });
                },
              ),

              const SizedBox(height: 12),
              _buildDropdown(
                l10n.studyYear,
                _studyYears,
                selectedStudyYear,
                (val) {
                  setState(() => selectedStudyYear = val);
                },
              ),

              const SizedBox(height: 12),
              if (selectedCollege != null) // Only show sub-category if college is selected
                _buildDropdown(
                  l10n.subCategory,
                  _subCategories,
                  selectedSubCategory,
                  (val) {
                    setState(() => selectedSubCategory = val);
                  },
                ),

              const SizedBox(height: 20),
              AppWidgets.buildPrimaryButton(
                text: isEditing ? l10n.save : l10n.publish,
                onPressed: _submit,
                width: double.infinity,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return TextFormField(
      controller: controller,
      validator: (val) => val == null || val.isEmpty ? l10n.required : null,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: theme.cardColor,
      ),
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? selected, Function(String?) onChanged) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return DropdownButtonFormField<String>(
      value: selected,
      items: options.map((val) {
        String displayText;
        switch (val) {
          case 'collegeOfEngineering':
            displayText = l10n.collegeOfEngineering;
            break;
          case 'collegeOfMedicine':
            displayText = l10n.collegeOfMedicine;
            break;
          case 'collegeOfDentistry':
            displayText = l10n.collegeOfDentistry;
            break;
          case 'collegeOfScience':
            displayText = l10n.collegeOfScience;
            break;
          case 'collegeOfArts':
            displayText = l10n.collegeOfArts;
            break;
          case 'collegeOfBusiness':
            displayText = l10n.collegeOfBusiness;
            break;
          case 'collegeOfEducation':
            displayText = l10n.collegeOfEducation;
            break;
          case 'collegeOfComputerScience':
            displayText = l10n.collegeOfComputerScience;
            break;
          case 'collegeOfArchitecture':
            displayText = l10n.collegeOfArchitecture;
            break;
          case 'collegeOfPharmacy':
            displayText = l10n.collegeOfPharmacy;
            break;
          case 'firstYear':
            displayText = l10n.firstYear;
            break;
          case 'secondYear':
            displayText = l10n.secondYear;
            break;
          case 'thirdYear':
            displayText = l10n.thirdYear;
            break;
          case 'fourthYear':
            displayText = l10n.fourthYear;
            break;
          case 'fifthYear':
            displayText = l10n.fifthYear;
            break;
          case 'sixthYear':
            displayText = l10n.sixthYear;
            break;
          case 'graduateStudent':
            displayText = l10n.graduateStudent;
            break;
          default:
            displayText = val;
        }
        return DropdownMenuItem(
          value: val,
          child: Text(displayText),
        );
      }).toList(),
      onChanged: onChanged,
      validator: (val) => val == null ? l10n.required : null,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: theme.textTheme.bodyLarge?.color ?? Colors.black),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderGrey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.primaryBlue, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: theme.cardColor,
      ),
    );
  }
}