// Do search only on the Index Page
import { create, search, insert } from 'https://unpkg.com/@orama/orama@latest/dist/index.js'

// Create DB
const db = await create({
    schema: {
    doc_title: 'string',
    doc_color: 'string',
    text: 'string',
    heading_url: 'string',
    heading_text: 'string'
    }
})
// Load JSON DB
const response = await fetch("/data/specifications_db.json");
const data_rows = await response.json();
let i = 0;
while (i < data_rows.length) {
    await insert(db, {
        document: data_rows[i]["document"],
        doc_color: data_rows[i]["doc_color"],
        text: data_rows[i]["text"],
        heading_url: data_rows[i]["heading_url"],
        heading_text: data_rows[i]["heading_text"]
    })
    i++;
}

// Main db search function 
async function search_onKeyUp(){

    const search_input_text = document.getElementById("searchInput").value;
    // Close drop down when empty
    if ( search_input_text == ''){
        document.getElementById("search_dropdown").style.display = "none";
    }else{
        document.getElementById("search_dropdown").style.display = "block";
    }

    const searchResult = await search(db, {
        term: search_input_text,
        properties: ['text', 'heading_text'],
        exact: true,
        });
    if (searchResult == null){
        return;
    }
    //console.log(searchResult.hits.map((hit) => hit.document));

    // clear previous search
    const myNode = document.getElementById("search_dropdown");
    while (myNode.firstChild) {
        myNode.removeChild(myNode.lastChild);
    }

    if (searchResult.count == 0){

        const node = document.createElement("div");
        node.classList.add('search-item');
        const textnode = document.createTextNode("There are no matches found");
        node.appendChild(textnode);
        myNode.appendChild(node);

    }else{

        searchResult.hits.forEach ((value, index, array) =>{
            const doc_title = value.document["document"]
            const doc_color = value.document["doc_color"]
            const heading_url = value.document["heading_url"]
            const heading_text = value.document["heading_text"]
            const search_text = value.document["text"]

            const node_div = document.createElement("div");
            node_div.classList.add('search-item');

            const table = document.createElement("table");
            table.classList.add('search-result-table');
            node_div.appendChild(table);

            const tbody = document.createElement("tbody");
            table.appendChild(tbody);

            // Row 1
            let row = document.createElement("tr");
            let cell = document.createElement("td");
            let i = document.createElement("i");
                i.classList.add("fa","fa-file-text-o");
                i.style.backgroundColor = "#" + doc_color;
                cell.appendChild(i);
            let textnode = document.createTextNode("\xa0" + doc_title);
            cell.appendChild(textnode);
            row.appendChild(cell)
            cell = document.createElement("td");
            
            const a = document.createElement('a'); 
            const link = document.createTextNode(heading_text)
            a.appendChild(link);
            a.title = heading_text;
            a.href = heading_url;
            document.body.appendChild(a); 

            cell.appendChild(a);
            row.appendChild(cell)
            tbody.appendChild(row)

            // Row 2
            row = document.createElement("tr");
            cell = document.createElement("td");
            cell.colSpan = 2;
            let show_text_parts = search_text.split(" ", 10).join(" ");
            textnode = document.createTextNode(show_text_parts);
            cell.appendChild(textnode)
            row.appendChild(cell)
            tbody.appendChild(row)

            myNode.appendChild(node_div);
        })
    }
}


document.getElementById("searchInput").addEventListener("keyup", search_onKeyUp);

// Show when focus in
document.getElementById("searchInput").addEventListener("focusin", (event) => {
    // clear previous search
    const element = document.getElementById("search_dropdown");
    while (element.firstChild) {
        element.removeChild(element.lastChild);
    }
    // show
    const rect = document.getElementById("searchInput").getBoundingClientRect();
    element.style.left = rect.left +'px';
    element.style.top = rect.top + rect.height + 4 +'px';
    element.style.display = "block";
});
