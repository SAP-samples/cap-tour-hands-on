using Main from './main';

annotate Main.Categories with {

  CategoryName @assert.format: '^[A-Z][a-z]+(?:\W[A-Z][a-z]+)*$';

  Description  @assert: (case
    when length(Description) < 3 then 'Description too short'
  end);

}

annotate Main.Products : Supplier with @assert: (case
  when not exists Supplier then 'Supplier does not exist'
end);
