
直奔主题，NSUserDefaults是iOS开发中使用最多的数据持久化容器，使用中你是否有这些困惑：不知道key名称是什么，不知道返回数据value类型是什么。本方案对NSUserDefaults封装，为NSUserDefaults提供明确描述key及value类型的能力。

1.声明接口类QRDataPersistence,将需要存取的数据以属性形式在QRDataPersistence中声明。




2.在+initialize方法中取到所有属性的attributes,将属性的set/get方法指向类型通用set/get方法,如BOOL型属性bShowAlert:







2.为每种类型通用set/get方法中，如是非OC类型则把属性包装成OC类型，并调用全局通用set/get方法，此处需要传入_cmd作为key，注意经过method_setImplementation的方法的_cmd实际为原始方法名，如generalBoolSetter方法内的_cmd为setBShowAlert。

3.在全局通用set/get方法中，将_cmd转成原始属性名称，并调用NSUserDefaults的读写方法




4.set的方法名转属性名方法getPropertyNameFromSetter:取得方法名第4位字符（前3位为set，第4位为属性首字母），算出第4位字符的小写字母，将前4位替换为第4位的小写字母。


5.get的方法名即为属性名，所以直接返回即可：




6.至此，完成了所有属性的set/get方法调用NSUserDefaults的读取方法目标。
7.另外，本方案提供了属性名和key值转换的能力，适用于业务命名规范或老数据无缝迁移场景。




8.话不多少，直接上demo
