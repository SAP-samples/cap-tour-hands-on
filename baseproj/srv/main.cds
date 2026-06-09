using northwhisper from '../db/schema';

@path: '/northwhisper'
service Main {

  entity Products   as projection on northwhisper.Products;
  entity Suppliers  as projection on northwhisper.Suppliers;
  entity Categories as projection on northwhisper.Categories;

}
