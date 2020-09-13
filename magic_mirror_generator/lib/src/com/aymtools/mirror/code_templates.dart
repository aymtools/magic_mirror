const String codeTemplate = """
{{#imports}}
{{{importsPath}}}
{{/imports}}

class BeanFactoryInstance implements IBeanFactory{
  BeanFactoryInstance._();

  static BeanFactoryInstance _instance = BeanFactoryInstance._();
  
  static bool isRegistered = false;

  static void register() {
    if (isRegistered) return;
    isRegistered = true;
    BeanFactory.registerFactories(_instance);
  }
   
  @override
   dynamic newInstance(
      String key, String namedConstructor, Map<String, dynamic> uriParams,
      {dynamic params, bool canThrowException = false}) {
     try {
      dynamic result;
      if (result == null) {
        result = _newInstanceByCustomCreator(key, namedConstructor,
            params, uriParams, canThrowException);
      }
      if (result == null) {
        result = _newInstanceBySysCreator(key, namedConstructor,
            params, uriParams, canThrowException);
      }
      if (result == null && canThrowException) {
        throw BeanNotFoundException(key);
      }
      return result;
    } catch (e) {
      print(e);
      if (canThrowException) throw e;
      return null;
    }
  }
    
  dynamic _newInstanceByCustomCreator(String uri, String namedConstructorInUri, dynamic param,
      Map<String, String> uriParams, bool canThrowException) {
     switch (uri) {
        {{{createBeanInstanceByCustomCreator}}}
        default: 
        return null;
     }
  }
  
  dynamic _newInstanceBySysCreator(String uri, String namedConstructorInUri, dynamic param,
      Map<String, String> uriParams, bool canThrowException) {
     switch (uri) {
        {{{createBeanInstanceBySysCreator}}}
        default: 
        return null;
     }
  }
    
  @override
  dynamic invokeMethod(dynamic bean, String methodName,
      {Map<String, dynamic> params, bool canThrowException = true}) {
    switch (bean.runtimeType) {
       {{{invokeMethods}}}
    }
    if(canThrowException)
      throw NoSuchMethodException(bean.runtimeType , methodName);
  }
  
  @override
  dynamic getFieldValue(dynamic bean, String fieldName, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{getFields}}}
    }
    if(canThrowException)
      throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  @override
  void setFieldValue(dynamic bean, String fieldName, dynamic value, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{setFields}}}
    }
    if(canThrowException)
      throw NoSuchFieldException(bean.runtimeType , fieldName);
  }

  @override
  Map<String, dynamic> getFieldValues(dynamic bean, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{getAllFields}}}
    }
    return {};
  }
  
  @override
  void setFieldValues(dynamic bean, Map<String, dynamic> values, {bool canThrowException = true}) {
    switch (bean.runtimeType) {
        {{{setAllFields}}}
    }
  }
  
  @override
  List<String> loadTypeAdapter() => const <String>[{{{typeAdapters}}}];
  
  @override
  List<String> loadFactoryInitializer() => const <String>[{{{initializers}}}];
  
  //{{{{beanInfos}}}}
  Map<String,Type> beanInfos = const {};
  
  bool canNewInstance(String key, String namedConstructor) =>  beanInfos.containsValue(
        namedConstructor.isEmpty ? key : '\$key.\$namedConstructor');

  bool canRunInvoker(dynamic bean) => beanInfos.containsValue(bean.runtimeType);
}
""";
