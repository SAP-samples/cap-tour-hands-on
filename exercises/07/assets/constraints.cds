using Main from './main';

annotate Main.Categories with {

  Description  @assert: (case
    when Description is null then 'Description must be supplied'
    when length(Description) < 3 then 'Description too short'
  end);

  CategoryName @assert.format: '^[A-Z][a-z]+(?:\W[A-Z][a-z]+)*$';

}

annotate Main.Products : Supplier with @assert: (case
  when not exists Supplier then 'Supplier does not exist'
end);
