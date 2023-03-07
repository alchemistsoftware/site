interface route_entry
{
	TemplatePath: string,
    Title: string,
    Description: string,
};

const RoutesMap = new Map();

RoutesMap.set("/", {
    TemplatePath: "/templates/home.html",
    Title: "Alchemist: Home",
    Description: "This is the home page",
});
RoutesMap.set("about", {
    TemplatePath: "/templates/about.html",
    Title: "Alchemist: About",
    Description: "This is the about page",
});
RoutesMap.set("contact", {
    TemplatePath: "/templates/contact.html",
    Title: "Alchemist: Contact",
    Description: "This is the contact page",
});
RoutesMap.set("products", {
    TemplatePath: "/templates/products.html",
    Title: "Alchemist: Products",
    Description: "This is the products page",
});
RoutesMap.set("protex", {
    TemplatePath: "/templates/protex.html",
    Title: "Alchemist: Protex",
    Description: "This is the protex project page",
});

function TryGetElementByID(ElemId: string): HTMLElement
{
    const Elem = document.getElementById(ElemId);
    if (Elem == null)
    {
        throw `Element with id: '${ElemId}' wasn't found.`;
    }
    return Elem;
}

const LocationHandler = async () =>
{
    let Location: string = window.location.hash.replace("#", "");

    if (Location.length == 0) {
        Location = "/";
    }

    const Route = RoutesMap.get(Location)

    const HTML = await fetch(Route.TemplatePath)
        .then((Response) => Response.text());

    TryGetElementByID("content").innerHTML = HTML;

    document.title = Route.Title;

    const DescElem = document.querySelector('meta[name="description"]');
    if (DescElem !== null)
    {
        DescElem.setAttribute("content", Route.Description);
    }
};

window.addEventListener("hashchange", LocationHandler);

LocationHandler();
