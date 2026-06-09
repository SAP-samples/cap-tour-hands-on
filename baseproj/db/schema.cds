namespace northwhisper;

entity Products {
  key ProductID    : Integer;
      ProductName  : String;
      UnitPrice    : Decimal;
      Category     : Association to Categories;
      Supplier     : Association to Suppliers;
      UnitsInStock : Integer;
      Discontinued : Boolean;
}

entity Suppliers {
  key SupplierID  : Integer;
      CompanyName : String;
      City        : String;
      Country     : String;
      Products    : Association to many Products
                      on Products.Supplier = $self;
}

entity Categories {
  key CategoryID   : Integer;
      CategoryName : String;
      Description  : String;
      Products     : Association to many Products
                       on Products.Category = $self;
}
