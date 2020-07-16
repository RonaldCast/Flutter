import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/product.dart';
import 'package:provider/provider.dart';
import '../providers/products.dart';

class EditProductScreen extends StatefulWidget {
  static const routeName = 'edit-product';
  @override
  _EditProductState createState() => _EditProductState();
}

class _EditProductState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descriptionFocusNode = FocusNode();
  final _imageURLFocusNode = FocusNode();
  final _imageURLController = TextEditingController();
  final _form = GlobalKey<FormState>();

  var _editedProduct =
      Product(id: null, title: "", price: 0, description: '', imageUrl: '');

  var _initValues = {
    'title': '',
    'description': '',
    'price': '',
    'imageUrl': ''
  };

  @override
  void initState() {
    _imageURLFocusNode.addListener(_updateImageUrl);

    super.initState();
  }

  var _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      final productId = ModalRoute.of(context).settings.arguments as String;

      if (productId != null) {
        _editedProduct =
            Provider.of<Products>(context, listen: false).findById(productId);
        _initValues = {
          'title': _editedProduct.title,
          'description': _editedProduct.description,
          'price': _editedProduct.price.toString(),
          'imageUrl': ''
        };
        _imageURLController.text = _editedProduct.imageUrl;
      }
    }
    _isInit = false;
    super.didChangeDependencies();
  }

  void _updateImageUrl() {
    if (!_imageURLFocusNode.hasFocus) {
      if ((!_imageURLController.text.startsWith('http') &&
              !_imageURLController.text.startsWith('https')) ||
          (!_imageURLController.text.endsWith('.png') &&
              !_imageURLController.text.endsWith('.jpg') &&
              !_imageURLController.text.endsWith('.jpeg'))) {
        return;
      }
      setState(() {});
    }
  }

  void _saveForm() {
    //guarda cada datos de los formularios
    //si no se pone le currentState.save() no se guarda el valor de cada input.
    final isValid = _form.currentState.validate();
    if (!isValid) {
      return;
    }
    _form.currentState.save();
    if (_editedProduct.id != null) {
      Provider.of<Products>(context, listen: false)
          .updateProduct(_editedProduct.id, _editedProduct);
    } else {
      Provider.of<Products>(context, listen: false).addProvider(_editedProduct);
    }

    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _imageURLFocusNode.dispose();
    _priceFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _imageURLController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Edit Product'),
          actions: <Widget>[
            IconButton(
              icon: Icon(Icons.save),
              onPressed: () {
                _saveForm();
              },
            )
          ],
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _form,
            child: ListView(
              children: <Widget>[
                TextFormField(
                  initialValue: _initValues['title'],
                  decoration: InputDecoration(labelText: 'Title'),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    return value.isEmpty ? "Please provide a value" : null;
                  },
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_priceFocusNode);
                  }, // para que continue con el otro input
                  onSaved: (value) {
                    _editedProduct = Product(
                        id: _editedProduct.id,
                        isFavorite: _editedProduct.isFavorite,
                        title: value,
                        price: _editedProduct.price,
                        description: _editedProduct.description,
                        imageUrl: _editedProduct.imageUrl);
                  },
                ),
                TextFormField(
                  initialValue: _initValues['price'],
                  decoration: InputDecoration(labelText: 'Price'),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.number,
                  focusNode: _priceFocusNode,
                  onFieldSubmitted: (_) {
                    FocusScope.of(context).requestFocus(_descriptionFocusNode);
                  },
                  onSaved: (value) {
                    _editedProduct = Product(
                        id: _editedProduct.id,
                        isFavorite: _editedProduct.isFavorite,
                        title: _editedProduct.title,
                        price: double.parse(value),
                        description: _editedProduct.description,
                        imageUrl: _editedProduct.imageUrl);
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Please enter a price";
                    } else if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    } else if (double.parse(value) <= 0) {
                      return "Please enter a number greater than zero";
                    }
                    return null;
                  },
                ),
                TextFormField(
                  initialValue: _initValues['description'],
                  decoration: InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  keyboardType: TextInputType.multiline,
                  focusNode: _descriptionFocusNode,
                  onSaved: (value) {
                    _editedProduct = Product(
                        id: _editedProduct.id,
                        isFavorite: _editedProduct.isFavorite,
                        title: _editedProduct.title,
                        price: _editedProduct.price,
                        description: value,
                        imageUrl: _editedProduct.imageUrl);
                  },
                  validator: (value) {
                    if (value.isEmpty) {
                      return "Please enter a description.";
                    } else if (value.length < 10) {
                      return "Should be at least 10 characters long";
                    } else {
                      return null;
                    }
                  },
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(top: 8, right: 10),
                      decoration: BoxDecoration(
                          border: Border.all(width: 1, color: Colors.grey)),
                      child: _imageURLController.text.isEmpty
                          ? Text("Enter a URL")
                          : FittedBox(
                              child: Image.network(_imageURLController.text),
                              fit: BoxFit.cover,
                            ),
                    ),
                    Expanded(
                      child: TextFormField(
                        decoration: InputDecoration(labelText: 'Image URL'),
                        keyboardType: TextInputType.url,
                        textInputAction: TextInputAction.done,
                        controller: _imageURLController,
                        focusNode: _imageURLFocusNode,
                        onFieldSubmitted: (_) {
                          _saveForm();
                        },
                        onSaved: (value) {
                          _editedProduct = Product(
                              id: _editedProduct.id,
                              isFavorite: _editedProduct.isFavorite,
                              title: _editedProduct.title,
                              price: _editedProduct.price,
                              description: _editedProduct.description,
                              imageUrl: value);
                        },
                        validator: (value) {
                          if (value.isEmpty) {
                            return 'Please enter an image URL';
                          } else if (!value.startsWith('http') &&
                              !value.startsWith('http')) {
                            return 'Please enter a valid URL.';
                          } else if (!value.endsWith(".png") &&
                              !value.endsWith('.jpg') &&
                              !value.endsWith(".jpeg")) {
                            return "Please enter a valid image URL";
                          }
                        },
                      ),
                    )
                  ],
                )
              ],
            ),
          ),
        ));
  }
}
