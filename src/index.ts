interface route_entry
{
	TemplatePath: string,
    Title: string,
    Description: string,
};

const RoutesMap = new Map();

RoutesMap.set("home", {
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
RoutesMap.set("scary-craft", {
    TemplatePath: "/templates/scary_craft.html",
    Title: "Alchemist: Scary-Craft",
    Description: "Scary craft project page",
});

let caleb_github_events: Object[] = [];
async function getGithubEvents(): Promise<Object[]> {
    if (caleb_github_events.length > 0)
        return caleb_github_events;

    let promise = new Promise<Object[]>((resolve) => {
        fetch("https://api.github.com/users/cabarger/events/public")
            .then((Response) => {
                Response.text()
                    .then((response_json) => {
                        caleb_github_events = JSON.parse(response_json);
                        resolve(caleb_github_events);
                    });
            });
    });

    return (await promise);
}

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
        Location = "home";
    }

    const Route = RoutesMap.get(Location);
    TryGetElementByID("content").innerHTML =
        await fetch(Route.TemplatePath)
            .then((Response) => Response.text());

    // Do a specific thing depending on template
    switch (Location)
    {
        case "home": {
            const activity_element = TryGetElementByID("activity"); 
            await getGithubEvents().then(events => {
                events.forEach((event: any) => {
                    if (event.type == "PushEvent") {
                        let card = document.createElement("div");
                        card.className = "card"

                        let push_info = document.createElement("p");
                        push_info.innerHTML = event.created_at.slice(0, 10) + ": pushed " + event.payload.commits.length + " commits to " + `<a href="https://github.com/${event.repo.name}">${event.repo.name}</a>`;
                        card.appendChild(push_info);
                        event.payload.commits.forEach((commit: any) => {
                            let commit_message = document.createElement("p");
                            commit_message.innerHTML = commit.message;
                            card.appendChild(commit_message);
                        });
                        activity_element.appendChild(card);
                    }
                });
            });
        } break;
        case "protex": {
            TryGetElementByID("changelog").innerHTML =
                await fetch("/templates/protex_changelog.html")
                    .then((Response) => Response.text());
        } break;
        default: break;
    };

    document.title = Route.Title;
    const DescElem = document.querySelector('meta[name="description"]');
    if (DescElem !== null) {
        DescElem.setAttribute("content", Route.Description);
    }
};

window.addEventListener("hashchange", LocationHandler);

LocationHandler();
