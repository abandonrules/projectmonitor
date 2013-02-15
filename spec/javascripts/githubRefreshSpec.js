describe('GithubRefresh.init', function() {
  beforeEach(function() {
    var fixtures = [
      "<div class='github' style='display: none;'>",
      "</div>"
    ].join("\n");
    setFixtures(fixtures);
    jasmine.Clock.useMock();
    jasmine.Ajax.useMock();
  });

  afterEach(function() {
    GithubRefresh.cleanupTimeout();
  });

  describe("when the status is bad", function() {
    it("shows the github notification", function() {
      GithubRefresh.init();
      expect($(".github")).toBeHidden();

      for (var i=0; i < 4; i++) {
        jasmine.Clock.tick(30001);
        mostRecentAjaxRequest().response({
          status: 200,
          responseText: "{\"status\": \"bad\"}"
        });
      }
      expect($(".github")).toBeVisible();
      expect($(".github")).toHaveClass('bad');
    });
  });

  describe("when the status is good", function() {
    it("hides the github notification", function() {
      GithubRefresh.init();
      $(".github").show()

      jasmine.Clock.tick(30001);
      mostRecentAjaxRequest().response({
        status: 200,
        responseText: "{\"status\": \"good\"}"
      });
      expect($(".github")).toBeHidden();
    });
  });

  describe("when the status is unreachable", function() {
    it("hides the github notification", function() {
      GithubRefresh.init();
      $(".github").show()

      for (var i=0; i < 4; i++) {
        jasmine.Clock.tick(30001);
        mostRecentAjaxRequest().response({
          status: 200,
          responseText: "{\"status\": \"unreachable\"}"
        });
      }
      expect($(".github")).toBeVisible();
      expect($(".github")).toHaveClass('unreachable');
    });
  });
});

