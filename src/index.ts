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
RoutesMap.set("projects", {
    TemplatePath: "/templates/projects.html",
    Title: "Alchemist: Projects",
    Description: "This is the projects page",
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

    const Route = RoutesMap.get(Location);
    TryGetElementByID("content").innerHTML =
        await fetch(Route.TemplatePath)
            .then((Response) => Response.text());

    // Do a specific thing depending on page content

    switch (Location)
    {
        case "protex":
        {
            TryGetElementByID("changelog").innerHTML =
                await fetch("/templates/protex_changelog.html")
                    .then((Response) => Response.text());
        };
        default: break;
    };

    document.title = Route.Title;
    const DescElem = document.querySelector('meta[name="description"]');
    if (DescElem !== null)
    {
        DescElem.setAttribute("content", Route.Description);
    }
};

window.addEventListener("hashchange", LocationHandler);

LocationHandler();
