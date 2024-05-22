cell(style="display: flex; justify-content: space-between; align-items: center; background-color: #112244; padding: 10px 50px; color: #ffffff; top: 0; width: 100%; box-sizing: border-box;", [
    cell(style="font-size: 1.5em; font-weight: bold;",
        "APR Controller Dashboard"
    ),
])
page(model, partial=true, [@yield])
